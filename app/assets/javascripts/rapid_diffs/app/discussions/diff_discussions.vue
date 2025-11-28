<script>
import { mapActions } from 'pinia';
import { useDiffDiscussions } from '~/rapid_diffs/stores/diff_discussions';
import NoteableDiscussion from './noteable_discussion.vue';

export default {
  name: 'DiffDiscussions',
  components: {
    NoteableDiscussion,
  },
  props: {
    discussions: {
      type: Array,
      required: true,
    },
  },
  methods: {
    ...mapActions(useDiffDiscussions, [
      'addNote',
      'updateNote',
      'deleteNote',
      'editNote',
      'setEditingMode',
      'toggleDiscussionReplies',
      'requestLastNoteEditing',
      'startReplying',
      'stopReplying',
      'toggleAward',
    ]),
  },
};
</script>

<template>
  <div class="gl-rounded-[var(--content-border-radius)] gl-bg-default gl-text-default">
    <ul v-for="discussion in discussions" :key="discussion.id" class="gl-m-0 gl-list-none gl-p-0">
      <noteable-discussion
        :discussion="discussion"
        :request-last-note-editing="requestLastNoteEditing"
        @toggleDiscussionReplies="toggleDiscussionReplies(discussion)"
        @replyAdded="addNote"
        @noteUpdated="updateNote"
        @noteDeleted="deleteNote"
        @noteEdited="editNote"
        @startEditing="setEditingMode($event, true)"
        @cancelEditing="setEditingMode($event, false)"
        @startReplying="startReplying(discussion)"
        @stopReplying="stopReplying(discussion)"
        @toggleAward="toggleAward"
      />
    </ul>
  </div>
</template>
