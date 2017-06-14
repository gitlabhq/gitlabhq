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
    }
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
      :updateHandler="formUpdateHandler"
      :cancelHandler="formCancelHandler"
      :noteBody="note.note" />
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
