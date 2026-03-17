<script>
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_action';
import { ignoreWhilePending } from '~/lib/utils/ignore_while_pending';
import { clearDraft } from '~/lib/utils/autosave';
import NoteForm from './note_form.vue';
import DiffDiscussions from './diff_discussions.vue';

export default {
  name: 'DiffFileDiscussions',
  components: {
    NoteForm,
    DiffDiscussions,
  },
  inject: {
    store: { type: Object },
    userPermissions: {
      type: Object,
    },
    endpoints: {
      type: Object,
    },
  },
  props: {
    oldPath: {
      type: String,
      required: true,
    },
    newPath: {
      type: String,
      required: true,
    },
  },
  emits: ['empty'],
  computed: {
    allDiscussions() {
      return this.store.findFileDiscussionsForFile({
        oldPath: this.oldPath,
        newPath: this.newPath,
      });
    },
    discussions() {
      return this.allDiscussions.filter((d) => !d.isForm);
    },
    formDiscussion() {
      return this.allDiscussions.find((d) => d.isForm);
    },
    autosaveKey() {
      const path =
        this.oldPath === this.newPath ? this.oldPath : [this.oldPath, this.newPath].join('-');
      // eslint-disable-next-line @gitlab/require-i18n-strings
      return `${window.location.pathname}-${path}-file`;
    },
  },
  watch: {
    allDiscussions(value) {
      if (value.length === 0) this.$emit('empty');
    },
  },
  methods: {
    cancelReplyForm: ignoreWhilePending(async function cancelReplyForm() {
      if (this.formDiscussion?.noteBody) {
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
      this.store.removeNewFileDiscussionForm(this.formDiscussion);
    }),
    async saveNote(noteBody) {
      const {
        data: { discussion },
      } = await axios.post(this.endpoints.discussions, {
        note: {
          position: this.formDiscussion.position,
          note: noteBody,
        },
      });
      this.store.replaceDiscussionForm(this.formDiscussion, discussion);
    },
  },
};
</script>

<template>
  <div data-testid="file-discussions">
    <diff-discussions v-if="discussions.length" :discussions="discussions" />
    <div
      v-if="formDiscussion"
      class="gl-rounded-[var(--content-border-radius)] gl-bg-subtle gl-px-5 gl-py-4"
      :data-discussion-id="formDiscussion.id"
    >
      <note-form
        :autosave-key="autosaveKey"
        :autofocus="formDiscussion.shouldFocus"
        :note-body="formDiscussion.noteBody"
        :save-button-title="__('Comment')"
        :save-note="saveNote"
        restore-from-autosave
        @input="store.setDiscussionFormText(formDiscussion, $event)"
        @cancel="cancelReplyForm"
      />
    </div>
  </div>
</template>
