<script>
import { GlButton, GlAlert } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__, __ } from '~/locale';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { getIdFromGraphQLId, isGid } from '~/graphql_shared/utils';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import markdownEditorEventHub from '~/vue_shared/components/markdown/eventhub';
import { CLEAR_AUTOSAVE_ENTRY_EVENT } from '~/vue_shared/constants';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import {
  ADD_DISCUSSION_COMMENT_ERROR,
  ADD_IMAGE_DIFF_NOTE_ERROR,
  UPDATE_IMAGE_DIFF_NOTE_ERROR,
  UPDATE_NOTE_ERROR,
} from '../../utils/error_messages';

export default {
  name: 'DesignReplyForm',
  i18n: {
    primaryBtn: s__('DesignManagement|Discard changes'),
    cancelBtnCreate: s__('DesignManagement|Continue creating'),
    cancelBtnUpdate: s__('DesignManagement|Continue editing'),
    cancelCreate: s__('DesignManagement|Are you sure you want to cancel creating this comment?'),
    cancelUpdate: s__('DesignManagement|Are you sure you want to cancel editing this comment?'),
    newCommentButton: s__('DesignManagement|Comment'),
    updateCommentButton: s__('DesignManagement|Save comment'),
  },
  markdownDocsPath: helpPagePath('user/markdown'),
  components: {
    MarkdownEditor,
    GlButton,
    GlAlert,
  },
  props: {
    designNoteMutation: {
      type: Object,
      required: true,
    },
    mutationVariables: {
      type: Object,
      required: false,
      default: null,
    },
    markdownPreviewPath: {
      type: String,
      required: false,
      default: '',
    },
    isNewComment: {
      type: Boolean,
      required: false,
      default: true,
    },
    isDiscussion: {
      type: Boolean,
      required: false,
      default: true,
    },
    noteableId: {
      type: String,
      required: true,
    },
    discussionId: {
      type: String,
      required: false,
      default: 'new',
    },
    value: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      noteText: this.value,
      saving: false,
      noteUpdateDirty: false,
      isLoggedIn: isLoggedIn(),
      errorMessage: '',
      formFieldProps: {
        id: 'design-reply',
        name: 'design-reply',
        'aria-label': __('Description'),
        placeholder: __('Write a comment…'),
        'data-testid': 'note-textarea',
        class: 'note-textarea js-gfm-input js-autosize markdown-area',
      },
    };
  },
  computed: {
    hasValue() {
      return this.noteText.length > 0;
    },
    buttonText() {
      return this.isNewComment
        ? this.$options.i18n.newCommentButton
        : this.$options.i18n.updateCommentButton;
    },
    shortDiscussionId() {
      return isGid(this.discussionId) ? getIdFromGraphQLId(this.discussionId) : this.discussionId;
    },
    autosaveKey() {
      if (this.isLoggedIn) {
        return [
          s__('DesignManagement|Discussion'),
          getIdFromGraphQLId(this.noteableId),
          this.shortDiscussionId,
        ].join('/');
      }
      return '';
    },
  },
  beforeDestroy() {
    /**
     * https://gitlab.com/gitlab-org/gitlab/-/issues/388314
     * Reply form closes and component destroys
     * only when comment submission was successful,
     * so we're safe to clear autosave data here conditionally.
     */
    this.$nextTick(() => {
      markdownEditorEventHub.$emit(CLEAR_AUTOSAVE_ENTRY_EVENT, this.autosaveKey);
    });
  },
  methods: {
    handleInput() {
      /**
       * While the form is saving using ctrl+enter
       * Do not mark it as dirty.
       *
       */
      if (!this.saving) {
        this.noteUpdateDirty = true;
      }
    },
    submitForm() {
      if (this.hasValue) {
        this.saving = true;
        this.$apollo
          .mutate({
            mutation: this.designNoteMutation,
            variables: {
              input: {
                ...this.mutationVariables,
                body: this.noteText,
              },
            },
            update: () => {
              this.noteUpdateDirty = false;
            },
          })
          .then((response) => {
            this.$emit('note-submit-complete', response);
          })
          .catch(() => {
            this.errorMessage = this.getErrorMessage();
          })
          .finally(() => {
            this.saving = false;
          });
      }
    },
    getErrorMessage() {
      if (this.isNewComment) {
        return this.isDiscussion ? ADD_IMAGE_DIFF_NOTE_ERROR : ADD_DISCUSSION_COMMENT_ERROR;
      }
      return this.isDiscussion ? UPDATE_IMAGE_DIFF_NOTE_ERROR : UPDATE_NOTE_ERROR;
    },
    cancelComment() {
      if (this.hasValue && this.noteUpdateDirty) {
        this.confirmCancelCommentModal();
      } else {
        this.$emit('cancel-form');
        this.noteUpdateDirty = false;
      }
    },
    async confirmCancelCommentModal() {
      const msg = this.isNewComment
        ? this.$options.i18n.cancelCreate
        : this.$options.i18n.cancelUpdate;

      const cancelBtn = this.isNewComment
        ? this.$options.i18n.cancelBtnCreate
        : this.$options.i18n.cancelBtnUpdate;

      const confirmed = await confirmAction(msg, {
        primaryBtnText: this.$options.i18n.primaryBtn,
        cancelBtnText: cancelBtn,
        primaryBtnVariant: 'danger',
      });

      if (!confirmed) {
        return;
      }

      this.$emit('cancel-form');
      markdownEditorEventHub.$emit(CLEAR_AUTOSAVE_ENTRY_EVENT, this.autosaveKey);
    },
  },
};
</script>

<template>
  <form class="new-note common-note-form" @submit.prevent>
    <div v-if="errorMessage" class="gl-pb-3">
      <gl-alert variant="danger" @dismiss="errorMessage = null">
        {{ errorMessage }}
      </gl-alert>
    </div>
    <markdown-editor
      v-model="noteText"
      autofocus
      :markdown-docs-path="$options.markdownDocsPath"
      :render-markdown-path="markdownPreviewPath"
      :enable-autocomplete="true"
      :supports-quick-actions="false"
      :form-field-props="formFieldProps"
      @input="handleInput"
      @keydown.meta.enter="submitForm"
      @keydown.ctrl.enter="submitForm"
      @keydown.esc.stop="cancelComment"
    />
    <slot name="resolve-checkbox"></slot>
    <div class="note-form-actions !gl-mt-4 gl-flex">
      <gl-button
        ref="submitButton"
        :disabled="!hasValue"
        :loading="saving"
        class="gl-mr-3 !gl-w-auto"
        category="primary"
        variant="confirm"
        type="submit"
        data-track-action="click_button"
        data-testid="save-comment-button"
        @click="submitForm"
      >
        {{ buttonText }}
      </gl-button>
      <gl-button
        ref="cancelButton"
        class="!gl-w-auto"
        variant="default"
        category="primary"
        @click="cancelComment"
        >{{ __('Cancel') }}</gl-button
      >
    </div>
  </form>
</template>
