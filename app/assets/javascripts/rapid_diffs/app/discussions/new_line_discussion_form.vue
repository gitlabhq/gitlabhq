<script>
import { __, sprintf } from '~/locale';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_action';
import { ignoreWhilePending } from '~/lib/utils/ignore_while_pending';
import { clearDraft } from '~/lib/utils/autosave';
import { createAlert } from '~/alert';
import { SOMETHING_WENT_WRONG, SAVING_THE_COMMENT_FAILED } from '~/diffs/i18n';
import NoteForm from './note_form.vue';

export default {
  name: 'NewLineDiscussionForm',
  components: {
    NoteForm,
  },
  inject: {
    store: { type: Object },
    blobRawPath: { default: null },
  },
  props: {
    discussion: {
      type: Object,
      required: true,
    },
  },
  computed: {
    codeSuggestionsConfig() {
      const { lines = [], canSuggest = false, previewParams = null } = this.discussion;
      const posLineRange = this.discussion.position?.line_range;
      const lineRange = posLineRange
        ? { start: posLineRange.start.new_line, end: posLineRange.end.new_line }
        : null;
      return {
        canSuggest,
        lines,
        lineType: '',
        showPopover: false,
        blobRawPath: this.blobRawPath,
        previewParams,
        lineRange,
      };
    },
    autosaveKey() {
      const {
        old_path: oldPath,
        new_path: newPath,
        old_line: oldLine,
        new_line: newLine,
      } = this.discussion.position;
      const path = oldPath === newPath ? oldPath : [oldPath, newPath].join('-');
      const line = oldLine === newLine ? oldLine : [oldLine, newLine].join('-');
      return `${window.location.pathname}-${[path, line].join('-')}`;
    },
  },
  mounted() {
    this.store.setNewLineDiscussionFormAutofocus(this.discussion, false);
  },
  methods: {
    cancelReplyForm: ignoreWhilePending(async function cancelReplyForm() {
      if (this.discussion.noteBody) {
        const confirmed = await confirmAction(
          __('Are you sure you want to cancel creating this comment?'),
          {
            primaryBtnText: __('Discard changes'),
            cancelBtnText: __('Continue editing'),
          },
        );

        if (!confirmed) return;
      }

      clearDraft(this.autosaveKey);
      this.store.removeNewLineDiscussionForm(this.discussion);
    }),
    async saveNote(noteBody) {
      try {
        await this.store.createLineDiscussion(this.discussion, noteBody);
      } catch (e) {
        const reason = e.response?.data?.errors;
        const errorMessage = reason
          ? sprintf(SAVING_THE_COMMENT_FAILED, { reason })
          : SOMETHING_WENT_WRONG;
        createAlert({
          message: errorMessage,
          parent: this.$refs.root,
        });
      }
    },
    async saveDraft(noteBody) {
      try {
        await this.store.createDraftLineDiscussion(this.discussion, noteBody);
      } catch (e) {
        const reason = e.response?.data?.errors;
        const errorMessage = reason
          ? sprintf(SAVING_THE_COMMENT_FAILED, { reason })
          : SOMETHING_WENT_WRONG;
        createAlert({
          message: errorMessage,
          parent: this.$refs.root,
        });
      }
    },
  },
};
</script>

<template>
  <div
    ref="root"
    class="gl-rounded-[var(--content-border-radius)] gl-bg-subtle gl-px-4 gl-py-4"
    :data-discussion-id="discussion.id"
  >
    <note-form
      :autosave-key="autosaveKey"
      :autofocus="discussion.shouldFocus"
      :note-body="discussion.noteBody"
      :save-button-title="__('Comment')"
      :save-note="saveNote"
      :code-suggestions-config="codeSuggestionsConfig"
      :save-draft="store.createDraftLineDiscussion ? saveDraft : null"
      :has-drafts="Boolean(store.hasDrafts)"
      restore-from-autosave
      @input="store.setDiscussionFormText(discussion, $event)"
      @cancel="cancelReplyForm"
    />
  </div>
</template>
