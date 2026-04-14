<script>
import { __ } from '~/locale';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_action';
import { ignoreWhilePending } from '~/lib/utils/ignore_while_pending';
import { clearDraft } from '~/lib/utils/autosave';
import DiffFileDiscussionExpansion from '~/diffs/components/diff_file_discussion_expansion.vue';
import NoteForm from './note_form.vue';
import DiffDiscussions from './diff_discussions.vue';
import DraftNote from './draft_note.vue';

export default {
  name: 'DiffFileDiscussions',
  components: {
    DiffFileDiscussionExpansion,
    NoteForm,
    DiffDiscussions,
    DraftNote,
  },
  inject: {
    store: { type: Object },
    userPermissions: { type: Object },
    filePaths: { type: Object },
  },
  emits: ['empty'],
  computed: {
    allDiscussions() {
      return this.store.findAllFileDiscussionsForFile(this.filePaths);
    },
    collapsedDiscussions() {
      return this.allDiscussions.filter((d) => !d.isForm && !d.isDraft && d.hidden);
    },
    expandedDiscussions() {
      return this.allDiscussions.filter((d) => !d.isForm && !d.isDraft && !d.hidden);
    },
    drafts() {
      return this.allDiscussions.filter((d) => d.isDraft);
    },
    formDiscussion() {
      return this.allDiscussions.find((d) => d.isForm);
    },
    autosaveKey() {
      const { oldPath, newPath } = this.filePaths;
      const path = oldPath === newPath ? oldPath : [oldPath, newPath].join('-');
      // eslint-disable-next-line @gitlab/require-i18n-strings
      return `${window.location.pathname}-${path}-file`;
    },
    canStartReview() {
      return Boolean(this.store.createDraftFileDiscussion);
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
      await this.store.createFileDiscussion(this.formDiscussion, noteBody);
    },
    async saveDraft(noteBody) {
      await this.store.createDraftFileDiscussion(this.formDiscussion, noteBody);
    },
  },
};
</script>

<template>
  <div data-testid="file-discussions">
    <diff-file-discussion-expansion
      v-if="collapsedDiscussions.length"
      :discussions="collapsedDiscussions"
      class="!gl-px-4"
      :class="{ 'gl-border-b-0': expandedDiscussions.length === 0 }"
      @toggle="store.expandFileDiscussions(filePaths.oldPath, filePaths.newPath)"
    />
    <diff-discussions v-if="expandedDiscussions.length" :discussions="expandedDiscussions" />
    <draft-note v-for="discussion in drafts" :key="discussion.id" :draft="discussion.draft" />
    <div
      v-if="formDiscussion"
      class="gl-rounded-[var(--content-border-radius)] gl-bg-subtle gl-px-4 gl-py-4"
      :class="{
        'gl-border-t': expandedDiscussions.length !== 0 || collapsedDiscussions.length !== 0,
      }"
      :data-discussion-id="formDiscussion.id"
    >
      <note-form
        :autosave-key="autosaveKey"
        :autofocus="formDiscussion.shouldFocus"
        :note-body="formDiscussion.noteBody"
        :save-button-title="__('Comment')"
        :save-note="saveNote"
        :save-draft="canStartReview ? saveDraft : null"
        :has-drafts="Boolean(store.hasDrafts)"
        restore-from-autosave
        @input="store.setDiscussionFormText(formDiscussion, $event)"
        @cancel="cancelReplyForm"
      />
    </div>
  </div>
</template>
