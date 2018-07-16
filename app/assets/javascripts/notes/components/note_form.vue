<script>
import { mapGetters, mapActions } from 'vuex';
import eventHub from '../event_hub';
import issueWarning from '../../vue_shared/components/issue/issue_warning.vue';
import markdownField from '../../vue_shared/components/markdown/field.vue';
import issuableStateMixin from '../mixins/issuable_state';
import resolvable from '../mixins/resolvable';

export default {
  name: 'IssueNoteForm',
  components: {
    issueWarning,
    markdownField,
  },
  mixins: [issuableStateMixin, resolvable],
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
    markdownVersion: {
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
    lineCode: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      updatedNoteBody: this.noteBody,
      conflictWhileEditing: false,
      isSubmitting: false,
      isResolving: false,
      resolveAsThread: true,
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
      return !this.updatedNoteBody.length || this.isSubmitting;
    },
  },
  watch: {
    noteBody() {
      if (this.updatedNoteBody === this.noteBody) {
        this.updatedNoteBody = this.noteBody;
      } else {
        this.conflictWhileEditing = true;
      }
    },
  },
  mounted() {
    this.$refs.textarea.focus();
  },
  methods: {
    ...mapActions(['toggleResolveNote']),
    handleUpdate(shouldResolve) {
      const beforeSubmitDiscussionState = this.discussionResolved;
      this.isSubmitting = true;

      this.$emit('handleFormUpdate', this.updatedNoteBody, this.$refs.editNoteForm, () => {
        this.isSubmitting = false;

        if (shouldResolve) {
          this.resolveHandler(beforeSubmitDiscussionState);
        }
      });
    },
    editMyLastNote() {
      if (this.updatedNoteBody === '') {
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
      this.$emit('cancelForm', shouldConfirm, this.noteBody !== this.updatedNoteBody);
    },
  },
};
</script>

<template>
  <div
    ref="editNoteForm"
    class="note-edit-form current-note-edit-form js-discussion-note-form">
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
    <form
      :data-line-code="lineCode"
      class="edit-note common-note-form js-quick-submit gfm-form"
    >

      <issue-warning
        v-if="hasWarning(getNoteableData)"
        :is-locked="isLocked(getNoteableData)"
        :is-confidential="isConfidential(getNoteableData)"
      />

      <markdown-field
        :markdown-preview-path="markdownPreviewPath"
        :markdown-docs-path="markdownDocsPath"
        :markdown-version="markdownVersion"
        :quick-actions-docs-path="quickActionsDocsPath"
        :add-spacing-classes="false">
        <textarea
          id="note_note"
          ref="textarea"
          slot="textarea"
          :data-supports-quick-actions="!isEditing"
          v-model="updatedNoteBody"
          name="note[note]"
          class="note-textarea js-gfm-input js-note-text
js-autosize markdown-area js-vue-issue-note-form js-vue-textarea"
          aria-label="Description"
          placeholder="Write a comment or drag your files here…"
          @keydown.meta.enter="handleUpdate()"
          @keydown.ctrl.enter="handleUpdate()"
          @keydown.up="editMyLastNote()"
          @keydown.esc="cancelHandler(true)">
        </textarea>
      </markdown-field>
      <div class="note-form-actions clearfix">
        <button
          :disabled="isDisabled"
          type="button"
          class="js-vue-issue-save btn btn-save js-comment-button "
          @click="handleUpdate()">
          {{ saveButtonTitle }}
        </button>
        <button
          v-if="discussion.resolvable"
          class="btn btn-nr btn-default append-right-10 js-comment-resolve-button"
          @click.prevent="handleUpdate(true)"
        >
          {{ resolveButtonTitle }}
        </button>
        <button
          class="btn btn-cancel note-edit-cancel js-close-discussion-note-form"
          type="button"
          @click="cancelHandler()">
          Cancel
        </button>
      </div>
    </form>
  </div>
</template>
