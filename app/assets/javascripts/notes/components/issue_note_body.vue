<script>
import IssueNoteEditedText from './issue_note_edited_text.vue';
import IssueNoteAwardsList from './issue_note_awards_list.vue';
import IssueNoteForm from './issue_note_form.vue';

export default {
  props: {
    note: {
      type: Object,
      required: true,
    },
    isEditing: {
      type: Boolean,
      required: false,
      default: false,
    },
    formUpdateHandler: {
      type: Function,
      required: true,
    },
    formCancelHandler: {
      type: Function,
      required: true,
    },
  },
  components: {
    IssueNoteEditedText,
    IssueNoteAwardsList,
    IssueNoteForm,
  },
  methods: {
    renderGFM() {
      $(this.$refs['note-body']).renderGFM();
    },
    handleFormUpdate() {
      this.formUpdateHandler({
        note: this.$refs.noteForm.note,
      });
    },
  },
  mounted() {
    this.renderGFM();
  },
};
</script>

<template>
  <div
    ref="note-body"
    class="note-body">
    <div
      v-html="note.note_html"
      class="note-text md"></div>
    <issue-note-form
      v-if="isEditing"
      ref="noteForm"
      :updateHandler="handleFormUpdate"
      :cancelHandler="formCancelHandler"
      :noteBody="note.note" />
    <issue-note-edited-text
      v-if="note.last_edited_by"
      :editedAt="note.last_edited_at"
      :editedBy="note.last_edited_by"
      actionText="Edited" />
    <issue-note-awards-list
      v-if="note.award_emoji.length"
      :noteId="note.id"
      :noteAuthorId="note.author.id"
      :awards="note.award_emoji"
      :toggleAwardPath="note.toggle_award_path" />
  </div>
</template>
