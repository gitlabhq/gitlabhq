<script>
import { GlButton, GlModal } from '@gitlab/ui';
import $ from 'jquery';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';
import Autosave from '~/autosave';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { getIdFromGraphQLId, isGid } from '~/graphql_shared/utils';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';

export default {
  name: 'DesignReplyForm',
  components: {
    MarkdownField,
    GlButton,
    GlModal,
  },
  props: {
    markdownPreviewPath: {
      type: String,
      required: false,
      default: '',
    },
    value: {
      type: String,
      required: true,
    },
    isSaving: {
      type: Boolean,
      required: true,
    },
    isNewComment: {
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
  },
  data() {
    return {
      formText: this.value,
      isLoggedIn: isLoggedIn(),
    };
  },
  computed: {
    hasValue() {
      return this.value.trim().length > 0;
    },
    modalSettings() {
      if (this.isNewComment) {
        return {
          title: s__('DesignManagement|Cancel comment confirmation'),
          okTitle: s__('DesignManagement|Discard comment'),
          cancelTitle: s__('DesignManagement|Keep comment'),
          content: s__('DesignManagement|Are you sure you want to cancel creating this comment?'),
        };
      }
      return {
        title: s__('DesignManagement|Cancel comment update confirmation'),
        okTitle: s__('DesignManagement|Cancel changes'),
        cancelTitle: s__('DesignManagement|Keep changes'),
        content: s__('DesignManagement|Are you sure you want to cancel changes to this comment?'),
      };
    },
    buttonText() {
      return this.isNewComment
        ? s__('DesignManagement|Comment')
        : s__('DesignManagement|Save comment');
    },
    markdownDocsPath() {
      return helpPagePath('user/markdown');
    },
    shortDiscussionId() {
      return isGid(this.discussionId) ? getIdFromGraphQLId(this.discussionId) : this.discussionId;
    },
  },
  mounted() {
    this.focusInput();
  },
  methods: {
    submitForm() {
      if (this.hasValue) {
        this.$emit('submit-form');
        this.autosaveDiscussion.reset();
      }
    },
    cancelComment() {
      if (this.hasValue && this.formText !== this.value) {
        this.$refs.cancelCommentModal.show();
      } else {
        this.$emit('cancel-form');
      }
    },
    confirmCancelCommentModal() {
      this.$emit('cancel-form');
      this.autosaveDiscussion.reset();
    },
    focusInput() {
      this.$refs.textarea.focus();
      this.initAutosaveComment();
    },
    initAutosaveComment() {
      if (this.isLoggedIn) {
        this.autosaveDiscussion = new Autosave($(this.$refs.textarea), [
          s__('DesignManagement|Discussion'),
          getIdFromGraphQLId(this.noteableId),
          this.shortDiscussionId,
        ]);
      }
    },
  },
};
</script>

<template>
  <form class="new-note common-note-form" @submit.prevent>
    <markdown-field
      :markdown-preview-path="markdownPreviewPath"
      :enable-autocomplete="true"
      :textarea-value="value"
      :markdown-docs-path="markdownDocsPath"
      class="bordered-box"
    >
      <template #textarea>
        <textarea
          ref="textarea"
          :value="value"
          class="note-textarea js-gfm-input js-autosize markdown-area"
          dir="auto"
          data-supports-quick-actions="false"
          data-qa-selector="note_textarea"
          :aria-label="__('Description')"
          :placeholder="__('Write a comment…')"
          @input="$emit('input', $event.target.value)"
          @keydown.meta.enter="submitForm"
          @keydown.ctrl.enter="submitForm"
          @keyup.esc.stop="cancelComment"
        >
        </textarea>
      </template>
    </markdown-field>
    <slot name="resolve-checkbox"></slot>
    <div class="note-form-actions gl-display-flex">
      <gl-button
        ref="submitButton"
        :disabled="!hasValue || isSaving"
        class="gl-mr-3 gl-w-auto!"
        category="primary"
        variant="confirm"
        type="submit"
        data-track-action="click_button"
        data-qa-selector="save_comment_button"
        @click="submitForm"
      >
        {{ buttonText }}
      </gl-button>
      <gl-button
        ref="cancelButton"
        class="gl-w-auto!"
        variant="default"
        category="primary"
        @click="cancelComment"
        >{{ __('Cancel') }}</gl-button
      >
    </div>
    <gl-modal
      ref="cancelCommentModal"
      ok-variant="danger"
      :title="modalSettings.title"
      :ok-title="modalSettings.okTitle"
      :cancel-title="modalSettings.cancelTitle"
      modal-id="cancel-comment-modal"
      @ok="confirmCancelCommentModal"
      >{{ modalSettings.content }}
    </gl-modal>
  </form>
</template>
