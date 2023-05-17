<script>
import { GlButton } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__, __, sprintf } from '~/locale';
import Tracking from '~/tracking';
import {
  I18N_WORK_ITEM_ERROR_UPDATING,
  sprintfWorkItem,
  STATE_OPEN,
  STATE_EVENT_REOPEN,
  STATE_EVENT_CLOSE,
  TRACKING_CATEGORY_SHOW,
  i18n,
} from '~/work_items/constants';
import { getDraft, clearDraft, updateDraft } from '~/lib/utils/autosave';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import { getUpdateWorkItemMutation } from '~/work_items/components/update_work_item';

export default {
  constantOptions: {
    markdownDocsPath: helpPagePath('user/markdown'),
  },
  components: {
    GlButton,
    MarkdownEditor,
  },
  mixins: [Tracking.mixin()],
  inject: ['fullPath'],
  props: {
    workItemId: {
      type: String,
      required: true,
    },
    workItemType: {
      type: String,
      required: true,
    },
    ariaLabel: {
      type: String,
      required: true,
    },
    autosaveKey: {
      type: String,
      required: true,
    },
    isSubmitting: {
      type: Boolean,
      required: false,
      default: false,
    },
    initialValue: {
      type: String,
      required: false,
      default: '',
    },
    commentButtonText: {
      type: String,
      required: false,
      default: __('Comment'),
    },
    markdownPreviewPath: {
      type: String,
      required: true,
    },
    autocompleteDataSources: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    isNewDiscussion: {
      type: Boolean,
      required: false,
      default: false,
    },
    workItemState: {
      type: String,
      required: false,
      default: STATE_OPEN,
    },
    autofocus: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      commentText: getDraft(this.autosaveKey) || this.initialValue || '',
      updateInProgress: false,
    };
  },
  computed: {
    tracking() {
      return {
        category: TRACKING_CATEGORY_SHOW,
        label: 'work_item_task_status',
        property: `type_${this.workItemType}`,
      };
    },
    formFieldProps() {
      return {
        'aria-label': this.ariaLabel,
        placeholder: __('Write a comment or drag your files here…'),
        id: 'work-item-add-or-edit-comment',
        name: 'work-item-add-or-edit-comment',
      };
    },
    isWorkItemOpen() {
      return this.workItemState === STATE_OPEN;
    },
    toggleWorkItemStateText() {
      return this.isWorkItemOpen
        ? sprintf(__('Close %{workItemType}'), { workItemType: this.workItemType.toLowerCase() })
        : sprintf(__('Reopen %{workItemType}'), { workItemType: this.workItemType.toLowerCase() });
    },
    cancelButtonText() {
      return this.isNewDiscussion ? this.toggleWorkItemStateText : __('Cancel');
    },
  },
  methods: {
    setCommentText(newText) {
      /**
       * https://gitlab.com/gitlab-org/gitlab/-/issues/388314
       *
       * While the form is saving using meta+enter,
       * avoid updating the data which is cleared after form submission.
       */
      if (!this.isSubmitting) {
        this.commentText = newText;
        updateDraft(this.autosaveKey, this.commentText);
      }
    },
    async cancelEditing() {
      if (this.commentText && this.commentText !== this.initialValue) {
        const msg = s__('WorkItem|Are you sure you want to cancel editing?');

        const confirmed = await confirmAction(msg, {
          primaryBtnText: __('Discard changes'),
          cancelBtnText: __('Continue editing'),
          primaryBtnVariant: 'danger',
        });

        if (!confirmed) {
          return;
        }
      }

      this.$emit('cancelEditing');
      clearDraft(this.autosaveKey);
    },
    async toggleWorkItemState() {
      const input = {
        id: this.workItemId,
        stateEvent: this.isWorkItemOpen ? STATE_EVENT_CLOSE : STATE_EVENT_REOPEN,
      };

      this.updateInProgress = true;

      try {
        this.track('updated_state');

        const { mutation, variables } = getUpdateWorkItemMutation({
          workItemParentId: this.workItemParentId,
          input,
        });

        const { data } = await this.$apollo.mutate({
          mutation,
          variables,
        });

        const errors = data.workItemUpdate?.errors;

        if (errors?.length) {
          this.$emit('error', i18n.updateError);
        }
      } catch (error) {
        const msg = sprintfWorkItem(I18N_WORK_ITEM_ERROR_UPDATING, this.workItemType);

        this.$emit('error', msg);
        Sentry.captureException(error);
      }

      this.updateInProgress = false;
    },
    cancelButtonAction() {
      if (this.isNewDiscussion) {
        this.toggleWorkItemState();
      } else {
        this.cancelEditing();
      }
    },
  },
};
</script>

<template>
  <div class="timeline-discussion-body gl-overflow-visible!">
    <div class="note-body gl-p-0! gl-overflow-visible!">
      <form class="common-note-form gfm-form js-main-target-form gl-flex-grow-1">
        <markdown-editor
          :value="commentText"
          :render-markdown-path="markdownPreviewPath"
          :markdown-docs-path="$options.constantOptions.markdownDocsPath"
          :autocomplete-data-sources="autocompleteDataSources"
          :form-field-props="formFieldProps"
          :add-spacing-classes="false"
          data-testid="work-item-add-comment"
          class="gl-mb-5"
          use-bottom-toolbar
          supports-quick-actions
          :autofocus="autofocus"
          @input="setCommentText"
          @keydown.meta.enter="$emit('submitForm', commentText)"
          @keydown.ctrl.enter="$emit('submitForm', commentText)"
          @keydown.esc.stop="cancelEditing"
        />
        <gl-button
          category="primary"
          variant="confirm"
          data-testid="confirm-button"
          :disabled="!commentText.length"
          :loading="isSubmitting"
          @click="$emit('submitForm', commentText)"
          >{{ commentButtonText }}
        </gl-button>
        <gl-button
          data-testid="cancel-button"
          category="primary"
          class="gl-ml-3"
          :loading="updateInProgress"
          @click="cancelButtonAction"
          >{{ cancelButtonText }}
        </gl-button>
      </form>
    </div>
  </div>
</template>
