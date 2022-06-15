<script>
import { GlButton, GlFormGroup, GlSafeHtmlDirective } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { helpPagePath } from '~/helpers/help_page_helper';
import { getDraft, clearDraft, updateDraft } from '~/lib/utils/autosave';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { __, s__ } from '~/locale';
import Tracking from '~/tracking';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import workItemQuery from '../graphql/work_item.query.graphql';
import updateWorkItemWidgetsMutation from '../graphql/update_work_item_widgets.mutation.graphql';
import { i18n, TRACKING_CATEGORY_SHOW, WIDGET_TYPE_DESCRIPTION } from '../constants';

export default {
  directives: {
    SafeHtml: GlSafeHtmlDirective,
  },
  components: {
    GlButton,
    GlFormGroup,
    MarkdownField,
  },
  mixins: [Tracking.mixin()],
  inject: ['fullPath'],
  props: {
    workItemId: {
      type: String,
      required: true,
    },
  },
  markdownDocsPath: helpPagePath('user/markdown'),
  data() {
    return {
      workItem: {},
      isEditing: false,
      isSubmitting: false,
      isSubmittingWithKeydown: false,
      desc: '',
    };
  },
  apollo: {
    workItem: {
      query: workItemQuery,
      variables() {
        return {
          id: this.workItemId,
        };
      },
      skip() {
        return !this.workItemId;
      },
      error() {
        this.error = i18n.fetchError;
      },
    },
  },
  computed: {
    autosaveKey() {
      return this.workItemId;
    },
    canEdit() {
      return this.workItem?.userPermissions?.updateWorkItem;
    },
    tracking() {
      return {
        category: TRACKING_CATEGORY_SHOW,
        label: 'item_description',
        property: `type_${this.workItemType}`,
      };
    },
    descriptionHtml() {
      return this.workItemDescription?.descriptionHtml;
    },
    descriptionText: {
      get() {
        return this.desc;
      },
      set(desc) {
        this.desc = desc;
      },
    },
    workItemDescription() {
      return this.workItem?.widgets?.find((widget) => widget.type === WIDGET_TYPE_DESCRIPTION);
    },
    workItemType() {
      return this.workItem?.workItemType?.name;
    },
    markdownPreviewPath() {
      return `${gon.relative_url_root || ''}/${this.fullPath}/preview_markdown?target_type=${
        this.workItemType
      }`;
    },
  },
  methods: {
    async startEditing() {
      this.isEditing = true;

      this.desc = getDraft(this.autosaveKey) || this.workItemDescription?.description || '';

      await this.$nextTick();

      this.$refs.textarea.focus();
    },
    async cancelEditing() {
      const isDirty = this.desc !== this.workItemDescription?.description;

      if (isDirty) {
        const msg = s__('WorkItem|Are you sure you want to cancel editing?');

        const confirmed = await confirmAction(msg, {
          primaryBtnText: __('Discard changes'),
          cancelBtnText: __('Continue editing'),
        });

        if (!confirmed) {
          return;
        }
      }

      this.isEditing = false;
      clearDraft(this.autosaveKey);
    },
    onInput() {
      if (this.isSubmittingWithKeydown) {
        return;
      }

      updateDraft(this.autosaveKey, this.desc);
    },
    async updateWorkItem(event) {
      if (event.key) {
        this.isSubmittingWithKeydown = true;
      }

      this.isSubmitting = true;

      try {
        this.track('updated_description');

        const {
          data: { workItemUpdateWidgets },
        } = await this.$apollo.mutate({
          mutation: updateWorkItemWidgetsMutation,
          variables: {
            input: {
              id: this.workItem.id,
              descriptionWidget: {
                description: this.descriptionText,
              },
            },
          },
        });

        if (workItemUpdateWidgets.errors?.length) {
          throw new Error(workItemUpdateWidgets.errors[0]);
        }

        this.isEditing = false;
        clearDraft(this.autosaveKey);
      } catch (error) {
        this.$emit('error', error.message);
        Sentry.captureException(error);
      }

      this.isSubmitting = false;
    },
  },
};
</script>

<template>
  <gl-form-group
    v-if="isEditing"
    class="gl-pt-5 gl-mb-5 gl-mt-0! gl-border-t! gl-border-b"
    :label="__('Description')"
    label-for="work-item-description"
    label-class="gl-float-left"
  >
    <div class="gl-display-flex gl-justify-content-flex-end">
      <gl-button class="gl-ml-auto" data-testid="cancel" @click="cancelEditing">{{
        __('Cancel')
      }}</gl-button>
      <gl-button
        class="js-no-auto-disable gl-ml-4"
        category="primary"
        variant="confirm"
        :loading="isSubmitting"
        data-testid="save-description"
        @click="updateWorkItem"
        >{{ __('Save') }}</gl-button
      >
    </div>
    <markdown-field
      can-attach-file
      :textarea-value="descriptionText"
      :is-submitting="isSubmitting"
      :markdown-preview-path="markdownPreviewPath"
      :markdown-docs-path="$options.markdownDocsPath"
      class="gl-p-3 bordered-box"
    >
      <template #textarea>
        <textarea
          id="work-item-description"
          ref="textarea"
          v-model="descriptionText"
          :disabled="isSubmitting"
          class="note-textarea js-gfm-input js-autosize markdown-area"
          dir="auto"
          data-supports-quick-actions="false"
          :aria-label="__('Description')"
          :placeholder="__('Write a comment or drag your files here…')"
          @keydown.meta.enter="updateWorkItem"
          @keydown.ctrl.enter="updateWorkItem"
          @keydown.exact.esc.stop="cancelEditing"
          @input="onInput"
        ></textarea>
      </template>
    </markdown-field>
  </gl-form-group>
  <div v-else class="gl-pt-5 gl-mb-5 gl-border-t gl-border-b">
    <div class="gl-display-flex">
      <h3 class="gl-font-base gl-mt-0">{{ __('Description') }}</h3>
      <gl-button
        v-if="canEdit"
        class="gl-ml-auto"
        icon="pencil"
        data-testid="edit-description"
        @click="startEditing"
        >{{ __('Edit') }}</gl-button
      >
    </div>
    <div v-safe-html="descriptionHtml" class="md gl-mb-5"></div>
  </div>
</template>
