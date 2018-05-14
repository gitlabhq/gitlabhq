<script>
import $ from 'jquery';
import noteEditedText from './note_edited_text.vue';
import noteAwardsList from './note_awards_list.vue';
import noteAttachment from './note_attachment.vue';
import noteForm from './note_form.vue';
import TaskList from '../../task_list';
import autosave from '../mixins/autosave';

export default {
  components: {
    noteEditedText,
    noteAwardsList,
    noteAttachment,
    noteForm,
  },
  mixins: [autosave],
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
  computed: {
    noteBody() {
      return this.note.note;
    },
  },
  mounted() {
    this.renderGFM();
    this.initTaskList();

    if (this.isEditing) {
      this.initAutoSave(this.note.noteable_type);
    }
  },
  updated() {
    this.initTaskList();
    this.renderGFM();

    if (this.isEditing) {
      if (!this.autosave) {
        this.initAutoSave(this.note.noteable_type);
      } else {
        this.setAutoSave();
      }
    }
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
    handleFormUpdate(note, parentElement, callback) {
      this.$emit('handleFormUpdate', note, parentElement, callback);
    },
    formCancelHandler(shouldConfirm, isDirty) {
      this.$emit('cancelFormEdition', shouldConfirm, isDirty);
    },
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
    <note-form
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
    <note-edited-text
      v-if="note.last_edited_at"
      :edited-at="note.last_edited_at"
      :edited-by="note.last_edited_by"
      action-text="Edited"
    />
    <note-awards-list
      v-if="note.award_emoji.length"
      :note-id="note.id"
      :note-author-id="note.author.id"
      :awards="note.award_emoji"
      :toggle-award-path="note.toggle_award_path"
      :can-award-emoji="note.current_user.can_award_emoji"
    />
    <note-attachment
      v-if="note.attachment"
      :attachment="note.attachment"
    />
  </div>
</template>
