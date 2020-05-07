<script>
import { GlDeprecatedButton, GlModal } from '@gitlab/ui';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';

export default {
  name: 'DesignReplyForm',
  components: {
    MarkdownField,
    GlDeprecatedButton,
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
  },
  computed: {
    hasValue() {
      return this.value.trim().length > 0;
    },
  },
  mounted() {
    this.$refs.textarea.focus();
  },
  methods: {
    submitForm() {
      if (this.hasValue) this.$emit('submitForm');
    },
    cancelComment() {
      if (this.hasValue) {
        this.$refs.cancelCommentModal.show();
      } else {
        this.$emit('cancelForm');
      }
    },
  },
};
</script>

<template>
  <form class="new-note common-note-form" @submit.prevent>
    <markdown-field
      :markdown-preview-path="markdownPreviewPath"
      :can-attach-file="false"
      :enable-autocomplete="true"
      :textarea-value="value"
      markdown-docs-path="/help/user/markdown"
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
    <div class="note-form-actions d-flex justify-content-between">
      <gl-deprecated-button
        ref="submitButton"
        :disabled="!hasValue || isSaving"
        variant="success"
        type="submit"
        data-track-event="click_button"
        data-qa-selector="save_comment_button"
        @click="$emit('submitForm')"
      >
        {{ __('Comment') }}
      </gl-deprecated-button>
      <gl-deprecated-button ref="cancelButton" @click="cancelComment">{{
        __('Cancel')
      }}</gl-deprecated-button>
    </div>
    <gl-modal
      ref="cancelCommentModal"
      ok-variant="danger"
      :title="s__('DesignManagement|Cancel comment confirmation')"
      :ok-title="s__('DesignManagement|Discard comment')"
      :cancel-title="s__('DesignManagement|Keep comment')"
      modal-id="cancel-comment-modal"
      @ok="$emit('cancelForm')"
      >{{ s__('DesignManagement|Are you sure you want to cancel creating this comment?') }}
    </gl-modal>
  </form>
</template>
