<script>
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
    updateHandler: {
      type: Function,
      required: true,
    },
    cancelHandler: {
      type: Function,
      required: true,
    },
    saveButtonTitle: {
      type: String,
      required: false,
      default: 'Save comment',
    },
  },
  data() {
    return {
      initialNote: this.noteBody,
      note: this.noteBody,
      markdownPreviewUrl: '',
      markdownDocsUrl: '',
      conflictWhileEditing: false,
    };
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
  components: {
    markdownField,
  },
  methods: {
    handleUpdate() {
      this.updateHandler({
        note: this.note,
      });
    },
    editMyLastNote() {
      if (this.note === '') {
        const discussion = $(this.$el).closest('.discussion-notes');
        const myLastNoteId = discussion.find('.js-my-note').last().attr('id');

        if (myLastNoteId) {
          eventHub.$emit('enterEditMode', {
            noteId: parseInt(myLastNoteId.replace('note_', ''), 10),
          });
        }
      }
    },
  },
  computed: {
    isDirty() {
      return this.initialNote !== this.note;
    },
    noteHash() {
      return `#note_${this.noteId}`;
    },
  },
  mounted() {
    const issuableDataEl = document.getElementById('js-issuable-app-initial-data');
    const issueData = JSON.parse(issuableDataEl.innerHTML.replace(/&quot;/g, '"'));
    const { markdownDocs, markdownPreviewUrl } = issueData;

    this.markdownDocsUrl = markdownDocs;
    this.markdownPreviewUrl = markdownPreviewUrl;
    this.$refs.textarea.focus();
  },
};
</script>

<template>
  <div class="note-edit-form">
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
    <form class="edit-note common-note-form">
      <markdown-field
        :markdown-preview-url="markdownPreviewUrl"
        :markdown-docs="markdownDocsUrl"
        :addSpacingClasses="false">
        <textarea
          id="note-body"
          name="note[note]"
          class="note-textarea js-gfm-input js-autosize markdown-area js-note-text"
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
          @click="handleUpdate"
          type="button"
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
