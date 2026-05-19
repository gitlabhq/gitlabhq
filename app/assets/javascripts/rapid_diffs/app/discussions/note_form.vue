<script>
import { GlButton, GlSprintf, GlLink, GlAlert, GlFormCheckbox } from '@gitlab/ui';
import { __ } from '~/locale';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import { clearDraft } from '~/lib/utils/autosave';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import { trackSavedUsingEditor } from '~/vue_shared/components/markdown/tracking';
import { COMMENT_FORM } from '~/notes/i18n';
import { createAlert } from '~/alert';
import { getNoteFormErrorMessages } from '~/notes/utils';

export default {
  name: 'NoteForm',
  i18n: COMMENT_FORM,
  components: {
    MarkdownEditor,
    GlButton,
    GlSprintf,
    GlLink,
    GlAlert,
    GlFormCheckbox,
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
    saveDraft: {
      type: Function,
      required: false,
      default: null,
    },
    hasDrafts: {
      type: Boolean,
      required: false,
      default: false,
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
    canCancel: {
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
    codeSuggestionsConfig: {
      type: Object,
      required: false,
      default: () => ({ lines: [], lineType: '', canSuggest: false, showPopover: false }),
    },
    saveNoteErrorMessages: {
      type: Object,
      required: false,
      default: null,
    },
    showResolveDiscussionToggle: {
      type: Boolean,
      required: false,
      default: false,
    },
    discussionResolved: {
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
      isResolving: false,
      isUnresolving: true,
    };
  },
  computed: {
    renderMarkdownPath() {
      const { previewParams } = this.codeSuggestionsConfig;
      if (!previewParams) return this.endpoints.previewMarkdown;
      return mergeUrlParams(previewParams, this.endpoints.previewMarkdown);
    },
    draftButtonTitle() {
      return this.hasDrafts ? __('Add to review') : __('Start a review');
    },
    commentButtonTitle() {
      return this.saveDraft ? __('Add comment now') : this.saveButtonTitle;
    },
    commentButtonCategory() {
      return this.saveDraft ? 'secondary' : 'primary';
    },
    isSubmitDisabled() {
      return !this.editedNoteBody.length || this.isSubmitting;
    },
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
      clearDraft(this.autosaveKey);
      this.$emit('cancel', shouldConfirm && this.noteBody !== this.editedNoteBody);
    },
    handleKeySubmit(forceUpdate = false) {
      if (this.saveDraft && !forceUpdate) {
        this.handleDraftSubmit();
      } else {
        this.handleUpdate();
      }
      this.editedNoteBody = '';
    },
    newResolvedState() {
      return (
        (this.discussionResolved && !this.isUnresolving) ||
        (!this.discussionResolved && this.isResolving)
      );
    },
    shouldToggleResolved() {
      if (!this.showResolveDiscussionToggle) return false;
      return this.newResolvedState() !== this.discussionResolved;
    },
    async handleUpdate() {
      this.isSubmitting = true;
      const shouldResolve = this.shouldToggleResolved();
      trackSavedUsingEditor(
        this.$refs.markdownEditor.isContentEditorActive,
        `${this.noteableType}_note`,
      );
      try {
        await this.saveNote(this.editedNoteBody, shouldResolve);
        this.editedNoteBody = '';
        clearDraft(this.autosaveKey);
      } catch (error) {
        createAlert({
          message: getNoteFormErrorMessages(error.response, this.saveNoteErrorMessages),
          parent: this.$el,
          error,
        });
      } finally {
        this.isSubmitting = false;
      }
    },
    async handleDraftSubmit() {
      if (!this.saveDraft) return;
      this.isSubmitting = true;
      const resolveDiscussion = this.showResolveDiscussionToggle ? this.newResolvedState() : false;
      trackSavedUsingEditor(
        this.$refs.markdownEditor.isContentEditorActive,
        `${this.noteableType}_note`,
      );
      try {
        await this.saveDraft(this.editedNoteBody, resolveDiscussion);
        this.editedNoteBody = '';
        clearDraft(this.autosaveKey);
      } catch (error) {
        createAlert({
          message: getNoteFormErrorMessages(error.response, this.saveNoteErrorMessages),
          parent: this.$el,
          error,
        });
      } finally {
        this.isSubmitting = false;
      }
    },
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="conflictWhileEditing" variant="danger" class="gl-mb-3">
      <gl-sprintf
        :message="$options.i18n.editingConflictMessage"
        :placeholders="$options.i18n.editingConflictPlaceholder"
      >
        <template #link="{ content }">
          <gl-link v-if="noteId" :href="`#note_${noteId}`" target="_blank">{{ content }}</gl-link>
          <template v-else>{{ content }}</template>
        </template>
      </gl-sprintf>
    </gl-alert>
    <div class="flash-container gl-mb-5"></div>
    <form ref="form" class="edit-note common-note-form js-quick-submit gfm-form">
      <markdown-editor
        ref="markdownEditor"
        v-model="editedNoteBody"
        :code-suggestions-config="codeSuggestionsConfig"
        :render-markdown-path="renderMarkdownPath"
        :markdown-docs-path="endpoints.markdownDocs"
        :noteable-type="noteableType"
        :form-field-props="formFieldProps"
        :autosave-key="autosaveKey"
        :autocomplete-data-sources="autocompleteDataSources"
        :disabled="isSubmitting"
        :supports-quick-actions="supportsQuickActions"
        :autofocus="autofocus"
        :restore-from-autosave="restoreFromAutosave"
        @input="$emit('input', $event)"
        @keydown.shift.meta.enter="handleKeySubmit(true)"
        @keydown.shift.ctrl.enter="handleKeySubmit(true)"
        @keydown.meta.enter.exact="handleKeySubmit()"
        @keydown.ctrl.enter.exact="handleKeySubmit()"
        @keydown.exact.up="editMyLastNote()"
        @keydown.exact.esc="cancel(true)"
        @handleSuggestDismissed="$emit('handleSuggestDismissed')"
      />
      <div class="gl-mt-3">
        <template v-if="showResolveDiscussionToggle">
          <label v-if="discussionResolved" class="gl-mb-0 gl-py-3">
            <gl-form-checkbox v-model="isUnresolving" data-testid="unresolve-checkbox">
              {{ __('Reopen thread') }}
            </gl-form-checkbox>
          </label>
          <label v-else class="gl-mb-0 gl-py-3">
            <gl-form-checkbox v-model="isResolving" data-testid="resolve-checkbox">
              {{ __('Resolve thread') }}
            </gl-form-checkbox>
          </label>
        </template>
        <div class="gl-flex gl-flex-wrap gl-gap-4">
          <gl-button
            v-if="saveDraft"
            :disabled="isSubmitDisabled"
            category="primary"
            variant="confirm"
            data-testid="add-to-review-button"
            @click="handleDraftSubmit()"
          >
            {{ draftButtonTitle }}
          </gl-button>
          <gl-button
            :disabled="isSubmitDisabled"
            :category="commentButtonCategory"
            variant="confirm"
            data-testid="reply-comment-button"
            @click="handleUpdate()"
          >
            {{ commentButtonTitle }}
          </gl-button>
          <gl-button
            v-if="canCancel"
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
