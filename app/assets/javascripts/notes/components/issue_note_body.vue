<script>
import IssueNoteEditedText from './issue_note_edited_text.vue';
import IssueNoteAwardsList from './issue_note_awards_list.vue';

export default {
  props: {
    note: {
      type: Object,
      required: true,
    },
  },
  components: {
    IssueNoteEditedText,
    IssueNoteAwardsList,
  },
};
</script>

<template>
  <div class="note-body">
    <div
      v-html="note.note_html"
      class="note-text md"></div>
    <issue-note-edited-text
      v-if="note.last_edited_by"
      :editedAt="note.last_edited_at"
      :editedBy="note.last_edited_by"
      actionText="Edited" />
    <issue-note-awards-list
      v-if="note.award_emoji.length"
      :awards="note.award_emoji" />
  </div>
</template>
