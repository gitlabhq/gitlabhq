<script>
  import { mapGetters } from 'vuex';
  import eventHub from '../event_hub';
  import issueWarning from '../../vue_shared/components/issue/issue_warning.vue';
  import markdownField from '../../vue_shared/components/markdown/field.vue';
  import issuableStateMixin from '../mixins/issuable_state';

  export default {
    name: 'IssueNoteForm',
    components: {
      issueWarning,
      markdownField,
    },
    mixins: [
      issuableStateMixin,
    ],
    props: {
      noteBody: {
        type: String,
        required: false,
        default: '',
      },
      noteId: {
        type: Number,
        required: false,
        default: 0,
      },
      saveButtonTitle: {
        type: String,
        required: false,
        default: 'Save comment',
      },
      discussion: {
        type: Object,
        required: false,
        default: () => ({}),
      },
      isEditing: {
        type: Boolean,
        required: true,
      },
    },
    data() {
      return {
        note: this.noteBody,
        conflictWhileEditing: false,
        isSubmitting: false,
      };
    },
    computed: {
      ...mapGetters([
        'getDiscussionLastNote',
        'getNoteableData',
        'getNoteableDataByProp',
        'getNotesDataByProp',
        'getUserDataByProp',
      ]),
      noteHash() {
        return `#note_${this.noteId}`;
      },
      markdownPreviewPath() {
        return this.getNoteableDataByProp('preview_note_path');
      },
      markdownDocsPath() {
        return this.getNotesDataByProp('markdownDocsPath');
      },
      quickActionsDocsPath() {
        return !this.isEditing ? this.getNotesDataByProp('quickActionsDocsPath') : undefined;
      },
      currentUserId() {
        return this.getUserDataByProp('id');
      },
      isDisabled() {
        return !this.note.length || this.isSubmitting;
      },
    },
    watch: {
      noteBody() {
        if (this.note === this.noteBody) {
          this.note = this.noteBody;
        } else {
          this.conflictWhileEditing = true;
        }
      },
    },
    mounted() {
      this.$refs.textarea.focus();
    },
    methods: {
      handleUpdate() {
        this.isSubmitting = true;

        this.$emit('handleFormUpdate', this.note, this.$refs.editNoteForm, () => {
          this.isSubmitting = false;
        });
      },
      editMyLastNote() {
        if (this.note === '') {
          const lastNoteInDiscussion = this.getDiscussionLastNote(this.discussion);

          if (lastNoteInDiscussion) {
            eventHub.$emit('enterEditMode', {
              noteId: lastNoteInDiscussion.id,
            });
          }
        }
      },
      cancelHandler(shouldConfirm = false) {
        // Sends information about confirm message and if the textarea has changed
        this.$emit('cancelFormEdition', shouldConfirm, this.noteBody !== this.note);
      },
    },
  };
</script>

<template>
  <div
    ref="editNoteForm"
    class="note-edit-form current-note-edit-form">
    <div
      v-if="conflictWhileEditing"
      class="js-conflict-edit-warning alert alert-danger">
      This comment has changed since you started editing, please review the
      <a
        :href="noteHash"
        target="_blank"
        rel="noopener noreferrer">
        updated comment
      </a>
      to ensure information is not lost.
    </div>
    <div class="flash-container timeline-content"></div>
    <form class="edit-note common-note-form js-quick-submit gfm-form">

      <issue-warning
        v-if="hasWarning(getNoteableData)"
        :is-locked="isLocked(getNoteableData)"
        :is-confidential="isConfidential(getNoteableData)"
      />

      <markdown-field
        :markdown-preview-path="markdownPreviewPath"
        :markdown-docs-path="markdownDocsPath"
        :quick-actions-docs-path="quickActionsDocsPath"
        :add-spacing-classes="false">
        <textarea
          id="note_note"
          name="note[note]"
          class="note-textarea js-gfm-input
js-autosize markdown-area js-vue-issue-note-form js-vue-textarea"
          :data-supports-quick-actions="!isEditing"
          aria-label="Description"
          v-model="note"
          ref="textarea"
          slot="textarea"
          placeholder="Write a comment or drag your files here..."
          @keydown.meta.enter="handleUpdate()"
          @keydown.ctrl.enter="handleUpdate()"
          @keydown.up="editMyLastNote()"
          @keydown.esc="cancelHandler(true)">
        </textarea>
      </markdown-field>
      <div class="note-form-actions clearfix">
        <button
          type="button"
          @click="handleUpdate()"
          :disabled="isDisabled"
          class="js-vue-issue-save btn btn-save">
          {{ saveButtonTitle }}
        </button>
        <button
          @click="cancelHandler()"
          class="btn btn-cancel note-edit-cancel"
          type="button">
          Cancel
        </button>
      </div>
    </form>
  </div>
</template>
