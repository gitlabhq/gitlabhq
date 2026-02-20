<script>
import {
  GlButton,
  GlModal,
  GlFormTextarea,
  GlIcon,
  GlForm,
  GlFormInput,
  GlFormGroup,
  GlFormRadio,
  GlAlert,
  GlLink,
} from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import { SAVED_VIEW_VISIBILITY, ROUTES } from '~/work_items/constants';
import { saveSavedView } from 'ee_else_ce/work_items/list/utils';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  name: 'WorkItemsNewSavedViewModal',
  components: {
    GlIcon,
    GlForm,
    GlFormInput,
    GlFormGroup,
    GlFormRadio,
    GlFormTextarea,
    GlButton,
    GlModal,
    GlAlert,
    GlLink,
  },
  i18n: {
    descriptionValidation: s__('WorkItem|140 characters max'),
    validateTitle: s__('WorkItem|Title is required.'),
    privateView: s__('WorkItem|Only you can see and edit this view.'),
    subscriptionLimitWarningMessage: s__(
      'WorkItem|You have reached the maximum number of views in your list. If you add a view, the last view in your list will be removed.',
    ),
    learnMoreAboutViewLimits: s__('WorkItem|Learn more about view limits.'),
  },
  savedViewLimitsHelpPath: helpPagePath('user/work_items/saved_views.md', {
    anchor: 'saved-view-limits',
  }),
  inject: ['subscribedSavedViewLimit', 'isGroup'],
  model: {
    prop: 'show',
    event: 'hide',
  },
  props: {
    show: {
      type: Boolean,
      required: true,
    },
    savedView: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    fullPath: {
      type: String,
      required: true,
    },
    filters: {
      type: Object,
      required: false,
      default: () => {},
    },
    displaySettings: {
      type: Object,
      required: false,
      default: () => {},
    },
    sortKey: {
      type: String,
      required: true,
    },
    showSubscriptionLimitWarning: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['hide'],
  MAX_DESCRIPTION_LENGTH: 140,
  SAVED_VIEW_VISIBILITY,
  data() {
    return {
      savedViewDescription: this.savedView?.description,
      savedViewTitle: this.savedView?.name,
      isTitleValid: true,
      savedViewVisibility: this.getSavedViewVisibility(),
      error: '',
      showWarningOnOpen: false,
    };
  },
  computed: {
    modalTitle() {
      return this.isEdit ? s__('WorkItem|Edit view') : s__('WorkItem|New view');
    },
    submitButtonLabel() {
      return this.isEdit ? s__('WorkItem|Save') : s__('WorkItem|Create view');
    },
    isEdit() {
      return Boolean(this.savedView?.id);
    },
    canUpdateSavedViewVisibility() {
      return !this.isEdit || this.savedView?.userPermissions?.updateSavedViewVisibility;
    },
    visibilityText() {
      return sprintf(
        s__(
          'WorkItem|Anyone with access to this %{namespaceType} can add the view, and those with the Planner and above roles can edit it.',
        ),
        { namespaceType: this.isGroup ? __('group') : __('project') },
      );
    },
  },
  watch: {
    show: {
      immediate: true,
      handler(newValue) {
        this.savedViewTitle = this.savedView?.name;
        this.savedViewDescription = this.savedView?.description;
        this.savedViewVisibility = this.getSavedViewVisibility();
        if (newValue) {
          this.showWarningOnOpen = this.showSubscriptionLimitWarning;
        }
      },
    },
  },
  methods: {
    focusTitleInput() {
      this.$refs.savedViewTitle?.$el.focus();
    },
    validateTitle() {
      this.isTitleValid = Boolean(this.savedViewTitle?.trim());
    },
    async saveView() {
      this.validateTitle();

      if (!this.isTitleValid) {
        return;
      }
      const mutationKey = this.isEdit ? 'workItemSavedViewUpdate' : 'workItemSavedViewCreate';

      try {
        const { data } = await saveSavedView({
          isEdit: this.isEdit,
          isForm: true,
          namespacePath: this.fullPath,
          id: this.savedView?.id,
          name: this.savedViewTitle,
          description: this.savedViewDescription,
          isPrivate: this.savedViewVisibility === SAVED_VIEW_VISIBILITY.PRIVATE,
          filters: this.filters ?? {},
          displaySettings: this.displaySettings,
          sort: this.sortKey,
          userPermissions: this.savedView?.userPermissions,
          subscribed: this.savedView?.subscribed,
          mutationKey,
          apolloClient: this.$apollo,
          subscribedSavedViewLimit: this.subscribedSavedViewLimit,
        });

        if (data[mutationKey].errors?.length) {
          const fallback = this.isEdit
            ? s__('WorkItem|Something went wrong while saving the view')
            : s__('WorkItem|Something went wrong while creating the view');
          this.error = data[mutationKey].errors[0] || fallback;
          return;
        }

        if (!this.isEdit) {
          const newViewId = getIdFromGraphQLId(data[mutationKey].savedView.id);
          this.$router.push({
            name: ROUTES.savedView,
            params: { view_id: newViewId.toString() },
            query: undefined,
          });
        }

        this.$toast.show(
          this.isEdit ? s__('WorkItem|View has been saved.') : s__('WorkItem|New view created.'),
        );

        this.hideAddNewViewModal();
      } catch (e) {
        Sentry.captureException(e);
        this.error = this.isEdit
          ? s__('WorkItem|Something went wrong while saving the view')
          : s__('WorkItem|Something went wrong while creating the view');
      }
    },
    resetModal() {
      this.isTitleValid = true;
      this.savedViewTitle = '';
      this.savedViewDescription = '';
      this.savedViewVisibility = SAVED_VIEW_VISIBILITY.PRIVATE;
    },
    hideAddNewViewModal() {
      this.resetModal();
      this.$emit('hide', false);
    },
    getSavedViewVisibility() {
      if (!this.savedView?.id) {
        return SAVED_VIEW_VISIBILITY.PRIVATE;
      }
      return this.savedView?.isPrivate
        ? SAVED_VIEW_VISIBILITY.PRIVATE
        : SAVED_VIEW_VISIBILITY.SHARED;
    },
  },
};
</script>

<template>
  <gl-modal
    modal-id="create-saved-view-modal"
    modal-class="create-saved-view-modal"
    :aria-label="modalTitle"
    :title="modalTitle"
    :visible="show"
    body-class="!gl-pb-0"
    size="sm"
    hide-footer
    @shown="focusTitleInput"
    @hide="hideAddNewViewModal"
  >
    <div
      v-if="showWarningOnOpen && !isEdit"
      class="gl-mb-4 gl-flex gl-gap-3 gl-rounded-base gl-bg-orange-50 gl-p-3"
      data-testid="subscription-limit-warning"
    >
      <gl-icon name="warning" :size="16" class="gl-mt-1 gl-shrink-0 gl-text-orange-500" />
      <span class="gl-text-sm">
        {{ $options.i18n.subscriptionLimitWarningMessage }}
        <gl-link :href="$options.savedViewLimitsHelpPath" target="_blank">
          {{ $options.i18n.learnMoreAboutViewLimits }}
        </gl-link>
      </span>
    </div>
    <gl-form data-testid="add-new-saved-view-form" @submit.prevent="saveView">
      <gl-alert
        v-if="error"
        class="gl-mb-3"
        variant="danger"
        :dismissible="true"
        @dismiss="error = undefined"
      >
        {{ error }}
      </gl-alert>
      <gl-form-group
        :label="__('Title')"
        label-for="saved-view-title"
        data-testid="saved-view-title"
        :state="isTitleValid"
        :invalid-feedback="$options.i18n.validateTitle"
      >
        <gl-form-input
          id="saved-view-title"
          ref="savedViewTitle"
          v-model="savedViewTitle"
          autocomplete="off"
          autofocus
          :state="isTitleValid"
          @input="isTitleValid = true"
        />
      </gl-form-group>

      <gl-form-group
        :label="__('Description (optional)')"
        :description="$options.i18n.descriptionValidation"
        label-for="saved-view-description"
        data-testid="saved-view-description"
      >
        <gl-form-textarea
          id="saved-view-description"
          v-model="savedViewDescription"
          size="sm"
          :maxlength="$options.MAX_DESCRIPTION_LENGTH"
        />
      </gl-form-group>

      <gl-form-group
        v-if="canUpdateSavedViewVisibility"
        :label="__('Visibility')"
        label-for="saved-view-visibility"
        data-testid="saved-view-visibility"
      >
        <gl-form-radio
          id="saved-view-visibility"
          v-model="savedViewVisibility"
          :checked="savedViewVisibility"
          :value="$options.SAVED_VIEW_VISIBILITY.PRIVATE"
        >
          <span>
            <gl-icon name="lock" class="gl-shrink-0" variant="subtle" />
            {{ s__('WorkItem|Private') }}
          </span>
          <template #help>{{ $options.i18n.privateView }}</template>
        </gl-form-radio>
        <gl-form-radio v-model="savedViewVisibility" :value="$options.SAVED_VIEW_VISIBILITY.SHARED">
          <span>
            <gl-icon name="users" class="gl-shrink-0" variant="subtle" />
            {{ s__('WorkItem|Shared') }}
          </span>
          <template #help>{{ visibilityText }}</template>
        </gl-form-radio>
      </gl-form-group>
      <div v-else class="gl-mb-5 gl-flex gl-flex-col gl-gap-3">
        <label class="gl-m-0 gl-text-base gl-font-bold gl-text-strong">
          {{ __('Visibility') }}
        </label>
        <div class="gl-flex gl-items-start gl-gap-3">
          <div
            class="gl-flex gl-shrink-0 gl-items-center gl-justify-center gl-rounded-full gl-bg-strong gl-p-3"
          >
            <gl-icon name="users" variant="subtle" />
          </div>
          <div class="gl-flex gl-flex-col">
            <span class="gl-text-subtle">
              {{ s__('WorkItem|Shared') }}
            </span>
            <span data-testid="shared-read-only-help-text" class="gl-text-sm gl-text-subtle">
              {{ visibilityText }}
            </span>
          </div>
        </div>
      </div>

      <div class="gl-mb-5 gl-flex gl-justify-end gl-gap-3">
        <gl-button type="button" data-testid="cancel-button" @click="hideAddNewViewModal">
          {{ __('Cancel') }}
        </gl-button>
        <gl-button
          type="submit"
          variant="confirm"
          :disabled="!isTitleValid"
          data-testid="create-view-button"
        >
          {{ submitButtonLabel }}
        </gl-button>
      </div>
    </gl-form>
  </gl-modal>
</template>
