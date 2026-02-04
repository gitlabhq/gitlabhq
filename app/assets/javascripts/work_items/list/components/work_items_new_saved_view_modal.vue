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
} from '@gitlab/ui';
import { produce } from 'immer';

import { s__ } from '~/locale';
import { SAVED_VIEW_VISIBILITY, NEW_SAVED_VIEWS_GID } from '~/work_items/constants';
import getSubscribedSavedViewsQuery from '~/work_items/list/graphql/work_item_saved_views_namespace.query.graphql';
import createSavedViewMutation from '~/work_items/graphql/create_saved_view.mutation.graphql';
import updateSavedViewMutation from '~/work_items/graphql/update_saved_view.mutation.graphql';

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
  },
  i18n: {
    descriptionValidation: s__('WorkItem|140 characters max'),
    validateTitle: s__('WorkItem|Title is required.'),
    privateView: s__('WorkItem|Only you can see and edit this view.'),
    sharedView: s__(
      'WorkItem|Anyone with access to this project can add the view, and those with the Planner and above roles can edit it.',
    ),
  },
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
  },
  watch: {
    show: {
      immediate: true,
      handler() {
        this.savedViewTitle = this.savedView?.name;
        this.savedViewDescription = this.savedView?.description;
        this.savedViewVisibility = this.getSavedViewVisibility();
      },
    },
  },
  methods: {
    focusTitleInput() {
      this.$refs.savedViewTitle?.$el.focus();
    },
    validateTitle() {
      this.isTitleValid = Boolean(this.savedViewTitle.trim());
    },
    async saveSavedView() {
      this.validateTitle();

      if (!this.isTitleValid) {
        return;
      }

      const isPrivate = this.savedViewVisibility === SAVED_VIEW_VISIBILITY.PRIVATE;
      const mutation = this.isEdit ? updateSavedViewMutation : createSavedViewMutation;
      const mutationKey = this.isEdit ? 'workItemSavedViewUpdate' : 'workItemSavedViewCreate';

      const commonInput = {
        name: this.savedViewTitle,
        description: this.savedViewDescription || '',
        private: isPrivate,
        filters: this.filters ?? {},
        displaySettings: this.displaySettings ?? {},
        sort: this.sortKey,
      };

      const inputVariables = this.isEdit
        ? { id: this.savedView.id, ...commonInput }
        : { namespacePath: this.fullPath, ...commonInput };

      const commonSavedViewResponse = {
        name: this.savedViewTitle,
        description: this.savedViewDescription || '',
        isPrivate,
        filters: this.filters ?? {},
        displaySettings: this.displaySettings ?? {},
      };

      const optimisticResponse = {
        [mutationKey]: {
          errors: [],
          savedView: this.isEdit
            ? {
                id: this.savedView.id,
                ...commonSavedViewResponse,
                userPermissions: this.savedView.userPermissions,
                subscribed: this.savedView.subscribed,
              }
            : {
                id: NEW_SAVED_VIEWS_GID,
                ...commonSavedViewResponse,
                subscribed: true,
                userPermissions: { updateSavedView: true, deleteSavedView: true },
              },
        },
      };

      try {
        const { data } = await this.$apollo.mutate({
          mutation,
          variables: { input: inputVariables },
          optimisticResponse,
          update: (cache, { data: responseData }) => {
            const query = {
              query: getSubscribedSavedViewsQuery,
              variables: { fullPath: this.fullPath, subscribedOnly: false },
            };
            const sourceData = cache.readQuery(query);

            if (!sourceData) {
              return;
            }

            const newData = produce(sourceData, (draftState) => {
              const { savedView } = responseData[mutationKey];
              const { nodes: savedViews } = draftState.namespace.savedViews;

              if (this.isEdit) {
                const index = savedViews.findIndex(({ id }) => id === savedView.id);
                if (index !== -1) {
                  savedViews[index] = savedView;
                }
              } else {
                // TODO: shift the view to the overflow index rather than at last
                // Also, redirect it to the new view
                savedViews.push(savedView);
              }
            });

            cache.writeQuery({ ...query, data: newData });
          },
        });

        if (data[mutationKey].errors?.length) {
          this.error = s__('WorkItem|Something went wrong while saving the view');
          return;
        }

        this.$toast.show(
          this.isEdit ? s__('WorkItem|View has been saved.') : s__('WorkItem|New view created.'),
        );
        this.hideAddNewViewModal();
      } catch {
        this.error = s__('WorkItem|Something went wrong while saving the view');
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
    <gl-form data-testid="add-new-saved-view-form" @submit.prevent="saveSavedView">
      <gl-alert v-if="error" variant="danger" :dismissible="true" @dismiss="error = undefined">
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
          <template #help>{{ $options.i18n.sharedView }}</template>
        </gl-form-radio>
      </gl-form-group>

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
