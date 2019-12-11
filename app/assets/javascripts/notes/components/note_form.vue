<script>
import { mapGetters, mapActions } from 'vuex';
import noteFormMixin from 'ee_else_ce/notes/mixins/note_form';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import eventHub from '../event_hub';
import issueWarning from '../../vue_shared/components/issue/issue_warning.vue';
import markdownField from '../../vue_shared/components/markdown/field.vue';
import issuableStateMixin from '../mixins/issuable_state';
import resolvable from '../mixins/resolvable';
import { __, sprintf } from '~/locale';
import { getDraft, updateDraft } from '~/lib/utils/autosave';

export default {
  name: 'NoteForm',
  components: {
    issueWarning,
    markdownField,
  },
  mixins: [issuableStateMixin, resolvable, noteFormMixin],
  props: {
    noteBody: {
      type: String,
      required: false,
      default: '',
    },
    noteId: {
      type: [String, Number],
      required: false,
      default: '',
    },
    saveButtonTitle: {
      type: String,
      required: false,
      default: __('Save comment'),
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
    resolveDiscussion: {
      type: Boolean,
      required: false,
      default: false,
    },
    line: {
      type: Object,
      required: false,
      default: null,
    },
    note: {
      type: Object,
      required: false,
      default: null,
    },
    diffFile: {
      type: Object,
      required: false,
      default: null,
    },
    helpPagePath: {
      type: String,
      required: false,
      default: '',
    },
    autosaveKey: {
      type: String,
      required: false,
      default: '',
    },
    showSuggestPopover: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    let updatedNoteBody = this.noteBody;

    if (!updatedNoteBody && this.autosaveKey) {
      updatedNoteBody = getDraft(this.autosaveKey) || '';
    }

    return {
      updatedNoteBody,
      conflictWhileEditing: false,
      isSubmitting: false,
      isResolving: this.resolveDiscussion,
      isUnresolving: !this.resolveDiscussion,
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
      if (this.noteId) {
        return `#note_${this.noteId}`;
      }
      return '#';
    },
    diffParams() {
      if (this.diffFile) {
        return {
          filePath: this.diffFile.file_path,
          refs: this.diffFile.diff_refs,
        };
      } else if (this.note && this.note.position) {
        return {
          filePath: this.note.position.new_path,
          refs: this.note.position,
        };
      } else if (this.discussion && this.discussion.diff_file) {
        return {
          filePath: this.discussion.diff_file.file_path,
          refs: this.discussion.diff_file.diff_refs,
        };
      }

      return null;
    },
    markdownPreviewPath() {
      const notable = this.getNoteableDataByProp('preview_note_path');

      const previewSuggestions = this.line && this.diffParams;
      const params = previewSuggestions
        ? {
            preview_suggestions: previewSuggestions,
            line: this.line.new_line,
            file_path: this.diffParams.filePath,
            base_sha: this.diffParams.refs.base_sha,
            start_sha: this.diffParams.refs.start_sha,
            head_sha: this.diffParams.refs.head_sha,
          }
        : {};

      return mergeUrlParams(params, notable);
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
    discussionNote() {
      const discussionNote = this.discussion.id
        ? this.getDiscussionLastNote(this.discussion)
        : this.note;
      return discussionNote || {};
    },
    canSuggest() {
      return (
        this.getNoteableData.can_receive_suggestion &&
        (this.line && this.line.can_receive_suggestion)
      );
    },
    changedCommentText() {
      return sprintf(
        __(
          'This comment has changed since you started editing, please review the %{startTag}updated comment%{endTag} to ensure information is not lost.',
        ),
        {
          startTag: `<a href="${this.noteHash}" target="_blank" rel="noopener noreferrer">`,
          endTag: '</a>',
        },
        false,
      );
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
    shouldToggleResolved(shouldResolve, beforeSubmitDiscussionState) {
      // shouldBeResolved() checks the actual resolution state,
      // considering batchComments (EEP), if applicable/enabled.
      const newResolvedStateAfterUpdate =
        this.shouldBeResolved && this.shouldBeResolved(shouldResolve);

      const shouldToggleState =
        newResolvedStateAfterUpdate !== undefined &&
        beforeSubmitDiscussionState !== newResolvedStateAfterUpdate;

      return shouldResolve || shouldToggleState;
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
    onInput() {
      if (this.autosaveKey) {
        const { autosaveKey, updatedNoteBody: text } = this;
        updateDraft(autosaveKey, text);
      }
    },
  },
};
</script>

<template>
  <div ref="editNoteForm" class="note-edit-form current-note-edit-form js-discussion-note-form">
    <div
      v-if="conflictWhileEditing"
      class="js-conflict-edit-warning alert alert-danger"
      v-html="changedCommentText"
    ></div>
    <div class="flash-container timeline-content"></div>
    <form :data-line-code="lineCode" class="edit-note common-note-form js-quick-submit gfm-form">
      <issue-warning
        v-if="hasWarning(getNoteableData)"
        :is-locked="isLocked(getNoteableData)"
        :is-confidential="isConfidential(getNoteableData)"
        :locked-issue-docs-path="lockedIssueDocsPath"
        :confidential-issue-docs-path="confidentialIssueDocsPath"
      />

      <markdown-field
        :markdown-preview-path="markdownPreviewPath"
        :markdown-docs-path="markdownDocsPath"
        :quick-actions-docs-path="quickActionsDocsPath"
        :line="line"
        :note="discussionNote"
        :can-suggest="canSuggest"
        :add-spacing-classes="false"
        :help-page-path="helpPagePath"
        :show-suggest-popover="showSuggestPopover"
        @handleSuggestDismissed="() => $emit('handleSuggestDismissed')"
      >
        <textarea
          id="note_note"
          ref="textarea"
          slot="textarea"
          v-model="updatedNoteBody"
          :data-supports-quick-actions="!isEditing"
          name="note[note]"
          class="note-textarea js-gfm-input js-note-text js-autosize markdown-area js-vue-issue-note-form js-vue-textarea qa-reply-input"
          dir="auto"
          :aria-label="__('Description')"
          :placeholder="__('Write a comment or drag your files here…')"
          @keydown.meta.enter="handleKeySubmit()"
          @keydown.ctrl.enter="handleKeySubmit()"
          @keydown.exact.up="editMyLastNote()"
          @keydown.exact.esc="cancelHandler(true)"
          @input="onInput"
        ></textarea>
      </markdown-field>
      <div class="note-form-actions clearfix">
        <template v-if="showBatchCommentsActions">
          <p v-if="showResolveDiscussionToggle">
            <label>
              <template v-if="discussionResolved">
                <input
                  v-model="isUnresolving"
                  type="checkbox"
                  data-qa-selector="unresolve_review_discussion_checkbox"
                />
                {{ __('Unresolve thread') }}
              </template>
              <template v-else>
                <input
                  v-model="isResolving"
                  type="checkbox"
                  data-qa-selector="resolve_review_discussion_checkbox"
                />
                {{ __('Resolve thread') }}
              </template>
            </label>
          </p>
          <div>
            <button
              :disabled="isDisabled"
              type="button"
              class="btn btn-success qa-start-review"
              @click="handleAddToReview"
            >
              <template v-if="hasDrafts">{{ __('Add to review') }}</template>
              <template v-else>{{ __('Start a review') }}</template>
            </button>
            <button
              :disabled="isDisabled"
              type="button"
              class="btn qa-comment-now"
              @click="handleUpdate()"
            >
              {{ __('Add comment now') }}
            </button>
            <button
              class="btn note-edit-cancel js-close-discussion-note-form"
              type="button"
              @click="cancelHandler()"
            >
              {{ __('Cancel') }}
            </button>
          </div>
        </template>
        <template v-else>
          <button
            :disabled="isDisabled"
            type="button"
            class="js-vue-issue-save btn btn-success js-comment-button qa-reply-comment-button"
            @click="handleUpdate()"
          >
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
            @click="cancelHandler()"
          >
            {{ __('Cancel') }}
          </button>
        </template>
      </div>
    </form>
  </div>
</template>
