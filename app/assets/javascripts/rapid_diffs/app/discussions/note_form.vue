<script>
import { GlButton, GlSprintf, GlLink } from '@gitlab/ui';
import { __ } from '~/locale';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import { trackSavedUsingEditor } from '~/vue_shared/components/markdown/tracking';
import { COMMENT_FORM } from '~/notes/i18n';

export default {
  name: 'NoteForm',
  i18n: COMMENT_FORM,
  components: {
    MarkdownEditor,
    GlButton,
    GlSprintf,
    GlLink,
  },
  inject: {
    endpoints: {
      type: Object,
    },
    noteableType: {
      type: String,
    },
  },
  props: {
    noteBody: {
      type: String,
      required: false,
      default: '',
    },
    noteId: {
      type: String,
      required: false,
      default: undefined,
    },
    saveNote: {
      type: Function,
      required: true,
    },
    requestLastNoteEditing: {
      type: Function,
      required: false,
      default: undefined,
    },
    saveButtonTitle: {
      type: String,
      required: false,
      default: __('Save comment'),
    },
    internal: {
      type: Boolean,
      required: false,
      default: false,
    },
    autosaveKey: {
      type: String,
      required: false,
      default: '',
    },
    autofocus: {
      type: Boolean,
      required: false,
      default: true,
    },
    restoreFromAutosave: {
      type: Boolean,
      required: false,
      default: false,
    },
    supportsQuickActions: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      editedNoteBody: this.noteBody,
      conflictWhileEditing: false,
      isSubmitting: false,
      autocompleteDataSources: gl.GfmAutoComplete?.dataSources,
    };
  },
  computed: {
    formFieldProps() {
      return {
        id: 'note_note',
        name: 'note[note]',
        'aria-label': __('Reply to comment'),
        placeholder: this.internal
          ? this.$options.i18n.bodyPlaceholderInternal
          : this.$options.i18n.bodyPlaceholder,
        class: 'note-textarea js-gfm-input js-note-text markdown-area js-vue-issue-note-form',
        'data-testid': 'reply-field',
      };
    },
  },
  watch: {
    noteBody() {
      if (this.editedNoteBody === this.noteBody) return;
      this.conflictWhileEditing = true;
    },
  },
  methods: {
    // eslint-disable-next-line vue/no-unused-properties -- public method
    append(value) {
      this.$refs.markdownEditor.append(value);
    },
    editMyLastNote() {
      if (!this.requestLastNoteEditing || this.editedNoteBody !== '') return;
      if (this.requestLastNoteEditing()) this.cancel();
    },
    cancel(shouldConfirm = false) {
      // prevent closing the form when trying to close autocomplete
      if (this.$refs.form.querySelector('textarea.at-who-active')) return;
      this.$emit('cancel', shouldConfirm, this.noteBody !== this.editedNoteBody);
    },
    handleKeySubmit(shiftPressed = false) {
      this.handleUpdate(shiftPressed);
      this.editedNoteBody = '';
    },
    async handleUpdate(shiftPressed = false) {
      this.isSubmitting = true;
      trackSavedUsingEditor(
        this.$refs.markdownEditor.isContentEditorActive,
        `${this.noteableType}_note`,
      );
      try {
        await this.saveNote(this.editedNoteBody, shiftPressed);
      } finally {
        this.isSubmitting = false;
      }
    },
  },
};
</script>

<template>
  <div class="note-edit-form current-note-edit-form js-discussion-note-form">
    <div v-if="conflictWhileEditing" class="js-conflict-edit-warning alert alert-danger">
      <gl-sprintf
        :message="$options.i18n.editingConflictMessage"
        :placeholders="$options.i18n.editingConflictPlaceholder"
      >
        <template #link="{ content }">
          <gl-link v-if="noteId" :href="`#note_${noteId}`" target="_blank">{{ content }}</gl-link>
          <template v-else>{{ content }}</template>
        </template>
      </gl-sprintf>
    </div>
    <div class="flash-container"></div>
    <form ref="form" class="edit-note common-note-form js-quick-submit gfm-form">
      <markdown-editor
        ref="markdownEditor"
        v-model="editedNoteBody"
        :render-markdown-path="endpoints.previewMarkdown"
        :markdown-docs-path="endpoints.markdownDocs"
        :noteable-type="noteableType"
        :form-field-props="formFieldProps"
        :autosave-key="autosaveKey"
        :autocomplete-data-sources="autocompleteDataSources"
        :disabled="isSubmitting"
        :supports-quick-actions="supportsQuickActions"
        :autofocus="autofocus"
        :restore-from-autosave="restoreFromAutosave"
        @keydown.shift.meta.enter="handleKeySubmit(true)"
        @keydown.shift.ctrl.enter="handleKeySubmit(true)"
        @keydown.meta.enter.exact="handleKeySubmit()"
        @keydown.ctrl.enter.exact="handleKeySubmit()"
        @keydown.exact.up="editMyLastNote()"
        @keydown.exact.esc="cancel(true)"
        @handleSuggestDismissed="$emit('handleSuggestDismissed')"
      />
      <div class="note-form-actions gl-font-size-0">
        <div class="gl-display-sm-flex gl-font-size-0 gl-flex-wrap">
          <gl-button
            :disabled="!editedNoteBody.length || isSubmitting"
            category="primary"
            variant="confirm"
            data-testid="reply-comment-button"
            class="js-vue-issue-save js-comment-button gl-mb-3 @sm/panel:gl-mb-0 @sm/panel:gl-mr-3"
            @click="handleUpdate()"
          >
            {{ saveButtonTitle }}
          </gl-button>
          <gl-button
            class="note-edit-cancel js-close-discussion-note-form"
            category="secondary"
            variant="default"
            data-testid="cancel"
            @click="cancel(true)"
          >
            {{ $options.i18n.cancel }}
          </gl-button>
        </div>
      </div>
    </form>
  </div>
</template>
