<script>
  import { mapGetters } from 'vuex';
  import markdownField from '../../vue_shared/components/markdown/field.vue';
  import eventHub from '../event_hub';

  export default {
    props: {
      noteBody: {
        type: String,
        required: false,
        default: '',
      },
      noteId: {
        type: Number,
        required: false,
      },
      saveButtonTitle: {
        type: String,
        required: false,
        default: 'Save comment',
      },
      discussion: {
        type: Object,
        required: false,
      }
    },
    data() {
      const { getIssueData, getNotesData } =  this.$store.getters;

      return {
        initialNote: this.noteBody,
        note: this.noteBody,
        markdownPreviewUrl: getIssueData.preview_note_path,
        markdownDocsUrl: getNotesData.markdownDocs,
        quickActionsDocsUrl: getNotesData.quickActionsDocs,
        conflictWhileEditing: false,
      };
    },
    components: {
      markdownField,
    },
    computed: {
      ...mapGetters([
        'getDiscussionLastNote',
      ]),
      noteHash() {
        return `#note_${this.noteId}`;
      },
    },
    methods: {
      handleUpdate() {
        this.$emit('handleFormUpdate', this.note);
      },
      editMyLastNote() {
        if (this.note === '') {
          const lastNoteInDiscussion = this.getDiscussionLastNote(this.discussion, window.gon.current_user_id);

          if (lastNoteInDiscussion) {
            eventHub.$emit('enterEditMode', {
              noteId: lastNoteInDiscussion.id,
            });
          }
        }
      },
      cancelHandler(shouldConfirm = false) {
        // Sends information about confirm message and if the textarea has changed
        this.$emit('cancelFormEdition', shouldConfirm, this.initialNote !== this.note);
      }
    },
    mounted() {
      this.$refs.textarea.focus();
    },
    watch: {
      noteBody() {
        if (this.note === this.initialNote) {
          this.note = this.noteBody;
        } else {
          this.conflictWhileEditing = true;
        }
      },
    },
  };
</script>

<template>
  <div class="note-edit-form current-note-edit-form">
    <div
      v-if="conflictWhileEditing"
      class="js-conflict-edit-warning alert alert-danger">
      This comment has changed since you started editing, please review the
      <a
        :href="noteHash"
        target="_blank"
        rel="noopener noreferrer">updated comment</a>
        to ensure information is not lost.
    </div>
    <form
      class="edit-note common-note-form">
      <markdown-field
        :markdown-preview-url="markdownPreviewUrl"
        :markdown-docs="markdownDocsUrl"
        :quick-actions-docs="quickActionsDocsUrl"
        :add-spacing-classes="false">
        <textarea
          id="note-body"
          name="note[note]"
          class="note-textarea js-gfm-input js-autosize markdown-area"
          data-supports-slash-commands="true"
          data-supports-quick-actions="true"
          aria-label="Description"
          v-model="note"
          ref="textarea"
          slot="textarea"
          placeholder="Write a comment or drag your files here..."
          @keydown.meta.enter="handleUpdate"
          @keydown.up="editMyLastNote"
          @keydown.esc="cancelHandler(true)">
        </textarea>
      </markdown-field>
      <div class="note-form-actions clearfix">
        <button
          type="button"
           @click="handleUpdate"
          class="btn btn-nr btn-save">
          {{saveButtonTitle}}
        </button>
        <button
          @click="cancelHandler()"
          class="btn btn-nr btn-cancel note-edit-cancel"
          type="button">
          Cancel
        </button>
      </div>
    </form>
  </div>
</template>
