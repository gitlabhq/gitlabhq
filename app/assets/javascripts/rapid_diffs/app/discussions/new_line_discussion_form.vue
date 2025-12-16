<script>
import { mapActions } from 'pinia';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_action';
import { ignoreWhilePending } from '~/lib/utils/ignore_while_pending';
import { clearDraft } from '~/lib/utils/autosave';
import { useDiffDiscussions } from '~/rapid_diffs/stores/diff_discussions';
import { createAlert } from '~/alert';
import NoteForm from './note_form.vue';

export default {
  name: 'NewLineDiscussionForm',
  components: {
    NoteForm,
  },
  inject: {
    endpoints: {
      type: Object,
    },
  },
  props: {
    discussion: {
      type: Object,
      required: true,
    },
  },
  computed: {
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
    this.setNewLineDiscussionFormAutofocus(this.discussion, false);
  },
  methods: {
    ...mapActions(useDiffDiscussions, [
      'setNewLineDiscussionFormText',
      'removeNewLineDiscussionForm',
      'setNewLineDiscussionFormAutofocus',
      'replaceDiscussion',
    ]),
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
      this.removeNewLineDiscussionForm(this.discussion);
    }),
    async saveNote(noteBody) {
      try {
        const {
          data: { discussion },
        } = await axios.post(this.endpoints.discussions, {
          position: this.discussion.position,
          note_text: noteBody,
        });
        clearDraft(this.autosaveKey);
        this.replaceDiscussion(this.discussion, discussion);
      } catch (error) {
        createAlert({
          message: __('Failed to submit your comment. Please try again.'),
          parent: this.$refs.root,
          error,
        });
      }
    },
  },
};
</script>

<template>
  <div ref="root" class="gl-bg-subtle gl-px-5 gl-py-4" :data-discussion-id="discussion.id">
    <note-form
      :autosave-key="autosaveKey"
      :autofocus="discussion.shouldFocus"
      :note-body="discussion.noteBody"
      :save-note="saveNote"
      restore-from-autosave
      @input="setNewLineDiscussionFormText(discussion, $event)"
      @cancel="cancelReplyForm"
    />
  </div>
</template>
