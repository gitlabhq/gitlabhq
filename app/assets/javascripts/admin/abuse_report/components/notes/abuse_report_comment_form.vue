<script>
import { GlButton } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import { getDraft, clearDraft, updateDraft } from '~/lib/utils/autosave';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';

export default {
  name: 'AbuseReportCommentForm',
  i18n: {
    addReplyText: __('Add a reply'),
    placeholderText: __('Write a comment or drag your files here…'),
    cancelButtonText: __('Cancel'),
    confirmText: s__('Notes|Are you sure you want to cancel creating this comment?'),
    discardText: __('Discard changes'),
    continueEditingText: __('Continue editing'),
  },
  components: {
    GlButton,
    MarkdownEditor,
  },
  inject: ['uploadNoteAttachmentPath'],
  props: {
    abuseReportId: {
      type: String,
      required: true,
    },
    isSubmitting: {
      type: Boolean,
      required: false,
      default: false,
    },
    autosaveKey: {
      type: String,
      required: true,
    },
    initialValue: {
      type: String,
      required: false,
      default: '',
    },
    commentButtonText: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      commentText: getDraft(this.autosaveKey) || this.initialValue || '',
    };
  },
  computed: {
    formFieldProps() {
      return {
        'aria-label': this.$options.i18n.addReplyText,
        placeholder: this.$options.i18n.placeholderText,
        id: 'abuse-report-add-or-edit-comment',
        name: 'abuse-report-add-or-edit-comment',
      };
    },
    markdownDocsPath() {
      return helpPagePath('user/markdown');
    },
  },
  methods: {
    setCommentText(newText) {
      if (!this.isSubmitting) {
        this.commentText = newText;
        updateDraft(this.autosaveKey, this.commentText);
      }
    },
    async cancelEditing() {
      if (this.commentText && this.commentText !== this.initialValue) {
        const confirmed = await confirmAction(this.$options.i18n.confirmText, {
          primaryBtnText: this.$options.i18n.discardText,
          cancelBtnText: this.$options.i18n.continueEditingText,
          primaryBtnVariant: 'danger',
        });

        if (!confirmed) {
          return;
        }
      }

      this.$emit('cancelEditing');
      clearDraft(this.autosaveKey);
    },
  },
};
</script>

<template>
  <div class="timeline-discussion-body !gl-overflow-visible">
    <div class="note-body !gl-overflow-visible !gl-p-0">
      <form class="common-note-form gfm-form js-main-target-form new-note gl-grow">
        <markdown-editor
          :value="commentText"
          :enable-content-editor="false"
          render-markdown-path=""
          :uploads-path="uploadNoteAttachmentPath"
          :markdown-docs-path="markdownDocsPath"
          :form-field-props="formFieldProps"
          :autofocus="true"
          @input="setCommentText"
          @keydown.meta.enter="$emit('submitForm', { commentText })"
          @keydown.ctrl.enter="$emit('submitForm', { commentText })"
          @keydown.esc.stop="cancelEditing"
        />
        <div class="note-form-actions">
          <gl-button
            category="primary"
            variant="confirm"
            data-testid="comment-button"
            :disabled="!commentText.length"
            :loading="isSubmitting"
            @click="$emit('submitForm', { commentText })"
          >
            {{ commentButtonText }}
          </gl-button>
          <gl-button
            data-testid="cancel-button"
            category="primary"
            class="gl-ml-3"
            @click="cancelEditing"
            >{{ $options.i18n.cancelButtonText }}
          </gl-button>
        </div>
      </form>
    </div>
  </div>
</template>
