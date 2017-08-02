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
    },
    components: {
      issueNoteEditedText,
      issueNoteAwardsList,
      issueNoteForm,
    },
    computed: {
      noteBody() {
        return this.note.note;
      },
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
      handleFormUpdate(note) {
        this.$emit('handleFormUpdate', note);
      },
      formCancelHandler(shouldConfirm, isDirty) {
        this.$emit('cancelFormEdition', shouldConfirm, isDirty);
      }
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
      @handleFormUpdate="handleFormUpdate"
      @cancelFormEdition="formCancelHandler"
      :is-editing="isEditing"
      :note-body="noteBody"
      :note-id="note.id"
      />
    <textarea
      v-if="canEdit"
      v-model="note.note"
      :data-update-url="note.path"
      class="hidden js-task-list-field"></textarea>
    <issue-note-edited-text
      v-if="note.last_edited_by"
      :edited-at="note.last_edited_at"
      :edited-by="note.last_edited_by"
      action-text="Edited"
      />
    <issue-note-awards-list
      v-if="note.award_emoji.length"
      :note-id="note.id"
      :note-author-id="note.author.id"
      :awards="note.award_emoji"
      :toggle-award-path="note.toggle_award_path"
      />
  </div>
</template>
