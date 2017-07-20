<script>
import issueNoteEditedText from './issue_note_edited_text.vue';
import issueNoteAwardsList from './issue_note_awards_list.vue';
import issueNoteForm from './issue_note_form.vue';
import TaskList from '../../task_list';

export default {
  props: {
    note: {
      type: Object,
      required: true,
    },
    canEdit: {
      type: Boolean,
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
  computed: {
    noteBody() {
      return this.note.note;
    },
  },
  components: {
    issueNoteEditedText,
    issueNoteAwardsList,
    issueNoteForm,
  },
  methods: {
    renderGFM() {
      $(this.$refs['note-body']).renderGFM();
    },
    initTaskList() {
      if (this.canEdit) {
        this.taskList = new TaskList({
          dataType: 'note',
          fieldName: 'note',
          selector: '.notes',
        });
      }
    },
    handleFormUpdate() {
      this.formUpdateHandler({
        note: this.$refs.noteForm.note,
      });
    },
  },
  mounted() {
    this.renderGFM();
    this.initTaskList();
  },
  updated() {
    this.initTaskList();
  },
};
</script>

<template>
  <div
    :class="{ 'js-task-list-container': canEdit }"
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
      :noteBody="noteBody"
      :noteId="note.id" />
    <textarea
      v-if="canEdit"
      v-model="note.note"
      :data-update-url="note.path"
      class="hidden js-task-list-field"></textarea>
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
