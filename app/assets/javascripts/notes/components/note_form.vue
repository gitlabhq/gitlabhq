<script>
import { GlButton, GlSprintf, GlLink, GlFormCheckbox } from '@gitlab/ui';
import { mapGetters, mapActions, mapState } from 'vuex';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import glFeaturesFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import eventHub from '../event_hub';
import issuableStateMixin from '../mixins/issuable_state';
import resolvable from '../mixins/resolvable';
import { COMMENT_FORM } from '../i18n';
import CommentFieldLayout from './comment_field_layout.vue';

export default {
  i18n: COMMENT_FORM,
  name: 'NoteForm',
  components: {
    MarkdownEditor,
    CommentFieldLayout,
    GlButton,
    GlSprintf,
    GlLink,
    GlFormCheckbox,
  },
  mixins: [issuableStateMixin, resolvable, glFeaturesFlagMixin()],
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
    lines: {
      type: Array,
      required: false,
      default: () => [],
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
    isDraft: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      updatedNoteBody: this.noteBody,
      conflictWhileEditing: false,
      isSubmitting: false,
      isResolving: this.resolveDiscussion,
      isUnresolving: !this.resolveDiscussion,
      resolveAsThread: true,
      isSubmittingWithKeydown: false,
      formFieldProps: {
        id: 'note_note',
        name: 'note[note]',
        'aria-label': __('Reply to comment'),
        placeholder: this.$options.i18n.bodyPlaceholder,
        class: 'note-textarea js-gfm-input js-note-text markdown-area js-vue-issue-note-form',
        'data-qa-selector': 'reply_field',
      },
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
    ...mapState({
      withBatchComments: (state) => state.batchComments?.withBatchComments,
    }),
    ...mapGetters('batchComments', ['hasDrafts']),
    autocompleteDataSources() {
      return gl.GfmAutoComplete?.dataSources;
    },
    showBatchCommentsActions() {
      return this.withBatchComments && this.noteId === '' && !this.discussion.for_commit;
    },
    showResolveDiscussionToggle() {
      if (!this.discussion?.notes) return false;

      return (
        this.discussion?.notes
          .filter((n) => n.resolvable)
          .some((n) => n.current_user?.can_resolve_discussion) || this.isDraft
      );
    },
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
      return this.getNotesDataByProp('quickActionsDocsPath');
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
        this.getNoteableData.can_receive_suggestion && this.line && this.line.can_receive_suggestion
      );
    },
    changedCommentText() {
      return {
        text: __(
          'This comment changed after you started editing it. Review the %{startTag}updated comment%{endTag} to ensure information is not lost.',
        ),
        placeholder: { link: ['startTag', 'endTag'] },
      };
    },
    enableContentEditor() {
      return Boolean(this.glFeatures.contentEditorOnIssues);
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
    this.updatePlaceholder();
  },
  methods: {
    ...mapActions(['toggleResolveNote']),
    shouldToggleResolved(shouldResolve, beforeSubmitDiscussionState) {
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
      // check if any dropdowns are active before sending the cancelation event
      if (
        !this.$refs.markdownEditor.$el
          .querySelector('textarea')
          ?.classList.contains('at-who-active')
      ) {
        this.$emit('cancelForm', shouldConfirm, this.noteBody !== this.updatedNoteBody);
      }
    },
    updatePlaceholder() {
      this.formFieldProps.placeholder = this.discussionNote?.internal
        ? this.$options.i18n.bodyPlaceholderInternal
        : this.$options.i18n.bodyPlaceholder;
    },
    onInput(value) {
      this.updatedNoteBody = value;
    },
    handleKeySubmit() {
      if (this.showBatchCommentsActions) {
        this.handleAddToReview();
      } else {
        this.isSubmittingWithKeydown = true;
        this.handleUpdate();
      }
      this.updatedNoteBody = '';
    },
    handleUpdate(shouldResolve) {
      const beforeSubmitDiscussionState = this.discussionResolved;
      this.isSubmitting = true;

      this.$emit(
        'handleFormUpdate',
        this.updatedNoteBody,
        this.$refs.editNoteForm,
        () => {
          this.isSubmitting = false;

          if (this.shouldToggleResolved(shouldResolve, beforeSubmitDiscussionState)) {
            this.resolveHandler(beforeSubmitDiscussionState);
          }
        },
        this.discussionResolved ? !this.isUnresolving : this.isResolving,
      );
    },
    shouldBeResolved(resolveStatus) {
      if (this.withBatchComments) {
        return (
          (this.discussionResolved && !this.isUnresolving) ||
          (!this.discussionResolved && this.isResolving)
        );
      }

      return resolveStatus;
    },
    handleAddToReview() {
      // check if draft should resolve thread
      const shouldResolve =
        (this.discussionResolved && !this.isUnresolving) ||
        (!this.discussionResolved && this.isResolving);
      this.isSubmitting = true;

      this.$emit('handleFormUpdateAddToReview', this.updatedNoteBody, shouldResolve);
    },
    hasEmailParticipants() {
      return this.getNoteableData.issue_email_participants?.length;
    },
  },
};
</script>

<template>
  <div ref="editNoteForm" class="note-edit-form current-note-edit-form js-discussion-note-form">
    <div v-if="conflictWhileEditing" class="js-conflict-edit-warning alert alert-danger">
      <gl-sprintf :message="changedCommentText.text" :placeholders="changedCommentText.placeholder">
        <template #link="{ content }">
          <gl-link :href="noteHash" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </div>
    <div class="flash-container timeline-content"></div>
    <form :data-line-code="lineCode" class="edit-note common-note-form js-quick-submit gfm-form">
      <comment-field-layout
        :noteable-data="getNoteableData"
        :is-internal-note="discussionNote.internal"
      >
        <markdown-editor
          ref="markdownEditor"
          :enable-content-editor="enableContentEditor"
          :value="updatedNoteBody"
          :render-markdown-path="markdownPreviewPath"
          :markdown-docs-path="markdownDocsPath"
          :line="line"
          :lines="lines"
          :can-suggest="canSuggest"
          :add-spacing-classes="false"
          :help-page-path="helpPagePath"
          :note="discussionNote"
          :form-field-props="formFieldProps"
          :show-suggest-popover="showSuggestPopover"
          :quick-actions-docs-path="quickActionsDocsPath"
          :autosave-key="autosaveKey"
          :autocomplete-data-sources="autocompleteDataSources"
          :disabled="isSubmitting"
          supports-quick-actions
          autofocus
          @keydown.meta.enter="handleKeySubmit()"
          @keydown.ctrl.enter="handleKeySubmit()"
          @keydown.exact.up="editMyLastNote()"
          @keydown.exact.esc="cancelHandler(true)"
          @input="onInput"
          @handleSuggestDismissed="() => $emit('handleSuggestDismissed')"
        />
      </comment-field-layout>
      <div class="note-form-actions">
        <template v-if="showBatchCommentsActions">
          <p v-if="showResolveDiscussionToggle">
            <label>
              <template v-if="discussionResolved">
                <gl-form-checkbox v-model="isUnresolving" class="js-unresolve-checkbox">
                  {{ __('Unresolve thread') }}
                </gl-form-checkbox>
              </template>
              <template v-else>
                <gl-form-checkbox v-model="isResolving" class="js-resolve-checkbox">
                  {{ __('Resolve thread') }}
                </gl-form-checkbox>
              </template>
            </label>
          </p>
          <div class="gl-display-flex gl-flex-wrap gl-mb-n3">
            <gl-button
              :disabled="isDisabled"
              category="primary"
              variant="confirm"
              class="gl-sm-mr-3 gl-mb-3"
              data-qa-selector="start_review_button"
              @click="handleAddToReview"
            >
              <template v-if="hasDrafts">{{ __('Add to review') }}</template>
              <template v-else>{{ __('Start a review') }}</template>
            </gl-button>
            <gl-button
              :disabled="isDisabled"
              category="secondary"
              variant="confirm"
              data-qa-selector="comment_now_button"
              class="gl-sm-mr-3 gl-mb-3 js-comment-button"
              @click="handleUpdate()"
            >
              {{ __('Add comment now') }}
            </gl-button>
            <gl-button
              class="note-edit-cancel gl-mb-3 js-close-discussion-note-form"
              category="secondary"
              variant="default"
              data-testid="cancelBatchCommentsEnabled"
              @click="cancelHandler(true)"
            >
              {{ __('Cancel') }}
            </gl-button>
          </div>
        </template>
        <template v-else>
          <div class="gl-display-sm-flex gl-flex-wrap">
            <gl-button
              :disabled="isDisabled"
              category="primary"
              variant="confirm"
              data-qa-selector="reply_comment_button"
              class="gl-sm-mr-3 gl-xs-mb-3 js-vue-issue-save js-comment-button"
              @click="handleUpdate()"
            >
              {{ saveButtonTitle }}
            </gl-button>
            <gl-button
              v-if="discussion.resolvable"
              category="secondary"
              variant="default"
              class="gl-sm-mr-3 gl-xs-mb-3 js-comment-resolve-button"
              @click.prevent="handleUpdate(true)"
            >
              {{ resolveButtonTitle }}
            </gl-button>
            <gl-button
              class="note-edit-cancel js-close-discussion-note-form"
              category="secondary"
              variant="default"
              data-testid="cancel"
              @click="cancelHandler(true)"
            >
              {{ __('Cancel') }}
            </gl-button>
          </div>
        </template>
      </div>
    </form>
  </div>
</template>
