<script>
import { GlButton, GlSprintf, GlLink, GlFormCheckbox } from '@gitlab/ui';
import { mapState } from 'pinia';
// eslint-disable-next-line no-restricted-imports
import { mapGetters as mapVuexGetters, mapActions as mapVuexActions } from 'vuex';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import glAbilitiesMixin from '~/vue_shared/mixins/gl_abilities_mixin';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import { trackSavedUsingEditor } from '~/vue_shared/components/markdown/tracking';
import { useBatchComments } from '~/batch_comments/store';
import eventHub from '../event_hub';
import issuableStateMixin from '../mixins/issuable_state';
import resolvable from '../mixins/resolvable';
import { COMMENT_FORM } from '../i18n';
import { isSlashCommand } from '../utils';
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
    CommentTemperature: () =>
      import(
        /* webpackChunkName: 'comment_temperature' */ 'ee_component/ai/components/comment_temperature.vue'
      ),
  },
  mixins: [issuableStateMixin, resolvable, glAbilitiesMixin()],
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
  },
  data() {
    return {
      updatedNoteBody: this.noteBody,
      conflictWhileEditing: false,
      isSubmitting: false,
      isMeasuringCommentTemperature: false,
      isResolving: this.resolveDiscussion,
      isUnresolving: !this.resolveDiscussion,
      onSaveHandler: null,
      resolveAsThread: true,
      isSubmittingWithKeydown: false,
      formFieldProps: {
        id: 'note_note',
        name: 'note[note]',
        'aria-label': __('Reply to comment'),
        placeholder: this.$options.i18n.bodyPlaceholder,
        class: 'note-textarea js-gfm-input js-note-text markdown-area js-vue-issue-note-form',
        'data-testid': 'reply-field',
      },
    };
  },
  computed: {
    ...mapVuexGetters([
      'getDiscussionLastNote',
      'getNoteableData',
      'getNoteableDataByProp',
      'getNotesDataByProp',
      'getUserDataByProp',
    ]),
    ...mapState(useBatchComments, ['hasDrafts', 'withBatchComments', 'isMergeRequest']),
    autocompleteDataSources() {
      return gl.GfmAutoComplete?.dataSources;
    },
    showBatchCommentsActions() {
      return this.isMergeRequest && this.noteId === '' && !this.discussion.for_commit;
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
    noteableType() {
      return this.getNoteableData.noteableType;
    },
    diffParams() {
      if (this.diffFile) {
        return {
          filePath: this.diffFile.file_path,
          refs: this.diffFile.diff_refs,
        };
      }
      if (this.note && this.note.position) {
        return {
          filePath: this.note.position.new_path,
          refs: this.note.position,
        };
      }
      if (this.discussion && this.discussion.diff_file) {
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
    currentUserId() {
      return this.getUserDataByProp('id');
    },
    isDisabled() {
      return !this.updatedNoteBody.length || this.isSubmitting;
    },
    isInternalNote() {
      return this.discussionNote.internal || this.discussion.confidential;
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
    codeSuggestionsConfig() {
      return {
        canSuggest: this.canSuggest,
        line: this.line,
        lines: this.lines,
        showPopover: this.showSuggestPopover,
        diffFile: this.diffFile,
      };
    },
    shouldDisableField() {
      return this.isSubmitting && !this.isMeasuringCommentTemperature;
    },
    shouldMeasureNoteTemperature() {
      return !isSlashCommand(this.updatedNoteBody) && this.glAbilities.measureCommentTemperature;
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
    ...mapVuexActions(['toggleResolveNote']),
    shouldToggleResolved(beforeSubmitDiscussionState) {
      return (
        this.showResolveDiscussionToggle && beforeSubmitDiscussionState !== this.newResolvedState()
      );
    },
    newResolvedState() {
      return (
        (this.discussionResolved && !this.isUnresolving) ||
        (!this.discussionResolved && this.isResolving)
      );
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
    append(value) {
      this.$refs.markdownEditor.append(value);
    },
    handleKeySubmit(forceUpdate = false) {
      if (this.showBatchCommentsActions && !forceUpdate) {
        this.handleAddToReview();
      } else {
        this.isSubmittingWithKeydown = true;
        this.handleUpdate();
      }
      if (!this.isMeasuringCommentTemperature) {
        this.updatedNoteBody = '';
      }
    },
    runCommentTemperatureMeasurement(onSaveHandler) {
      this.isMeasuringCommentTemperature = true;
      this.$refs.commentTemperature.measureCommentTemperature();
      this.onSaveHandler = this[onSaveHandler].bind(this, { shouldMeasureTemperature: false });
    },
    handleUpdate({ shouldMeasureTemperature = true } = {}) {
      const beforeSubmitDiscussionState = this.discussionResolved;
      this.isSubmitting = true;
      if (shouldMeasureTemperature && this.shouldMeasureNoteTemperature) {
        this.runCommentTemperatureMeasurement('handleUpdate');
        return;
      }

      this.isMeasuringCommentTemperature = false;

      trackSavedUsingEditor(
        this.$refs.markdownEditor.isContentEditorActive,
        `${this.noteableType}_note`,
      );

      this.$emit(
        'handleFormUpdate',
        this.updatedNoteBody,
        this.$refs.editNoteForm,
        () => {
          this.isSubmitting = false;

          if (this.shouldToggleResolved(beforeSubmitDiscussionState)) {
            this.resolveHandler(beforeSubmitDiscussionState);
          }
        },
        this.discussionResolved ? !this.isUnresolving : this.isResolving,
      );
    },
    handleAddToReview({ shouldMeasureTemperature = true } = {}) {
      const clickType = this.hasDrafts ? 'noteFormAddToReview' : 'noteFormStartReview';
      // check if draft should resolve thread
      const shouldResolve =
        (this.discussionResolved && !this.isUnresolving) ||
        (!this.discussionResolved && this.isResolving);
      this.isSubmitting = true;
      if (shouldMeasureTemperature && this.shouldMeasureNoteTemperature) {
        this.runCommentTemperatureMeasurement('handleAddToReview');
        return;
      }

      this.isMeasuringCommentTemperature = false;

      eventHub.$emit(clickType, { name: clickType });
      this.$emit(
        'handleFormUpdateAddToReview',
        this.updatedNoteBody,
        shouldResolve,
        this.$refs.editNoteForm,
        () => {
          this.isSubmitting = false;
        },
      );
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
    <div class="flash-container"></div>
    <form :data-line-code="lineCode" class="edit-note common-note-form js-quick-submit gfm-form">
      <comment-field-layout
        :is-internal-note="discussionNote.internal"
        :note="updatedNoteBody"
        :noteable-data="getNoteableData"
      >
        <markdown-editor
          ref="markdownEditor"
          :value="updatedNoteBody"
          :render-markdown-path="markdownPreviewPath"
          :markdown-docs-path="markdownDocsPath"
          :code-suggestions-config="codeSuggestionsConfig"
          :add-spacing-classes="false"
          :help-page-path="helpPagePath"
          :note="discussionNote"
          :noteable-type="noteableType"
          :form-field-props="formFieldProps"
          :autosave-key="autosaveKey"
          :autocomplete-data-sources="autocompleteDataSources"
          :disabled="shouldDisableField"
          supports-quick-actions
          :autofocus="autofocus"
          :restore-from-autosave="restoreFromAutosave"
          @keydown.shift.meta.enter="handleKeySubmit((forceUpdate = true))"
          @keydown.shift.ctrl.enter="handleKeySubmit((forceUpdate = true))"
          @keydown.meta.enter.exact="handleKeySubmit()"
          @keydown.ctrl.enter.exact="handleKeySubmit()"
          @keydown.exact.up="editMyLastNote()"
          @keydown.exact.esc="cancelHandler(true)"
          @input="onInput"
          @handleSuggestDismissed="() => $emit('handleSuggestDismissed')"
        />
      </comment-field-layout>
      <comment-temperature
        v-if="glAbilities.measureCommentTemperature"
        ref="commentTemperature"
        v-model="updatedNoteBody"
        :item-id="getNoteableData.id"
        :item-type="getNoteableData.noteableType"
        :user-id="currentUserId"
        @save="onSaveHandler()"
      />
      <div class="note-form-actions gl-font-size-0">
        <template v-if="showResolveDiscussionToggle">
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
        </template>

        <template v-if="showBatchCommentsActions">
          <div class="-gl-mb-3 gl-flex gl-flex-wrap">
            <gl-button
              :disabled="isDisabled"
              category="primary"
              variant="confirm"
              class="gl-mb-3 sm:gl-mr-3"
              data-testid="start-review-button"
              @click="handleAddToReview"
            >
              <template v-if="hasDrafts">{{ __('Add to review') }}</template>
              <template v-else>{{ __('Start a review') }}</template>
            </gl-button>
            <gl-button
              :disabled="isDisabled"
              category="secondary"
              variant="confirm"
              data-testid="comment-now-button"
              class="js-comment-button gl-mb-3 sm:gl-mr-3"
              @click="handleUpdate()"
            >
              {{ __('Add comment now') }}
            </gl-button>
            <gl-button
              class="note-edit-cancel js-close-discussion-note-form gl-mb-3"
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
          <div class="gl-display-sm-flex gl-font-size-0 gl-flex-wrap">
            <gl-button
              :disabled="isDisabled"
              category="primary"
              variant="confirm"
              data-testid="reply-comment-button"
              class="js-vue-issue-save js-comment-button gl-mb-3 sm:gl-mb-0 sm:gl-mr-3"
              @click="handleUpdate()"
            >
              {{ saveButtonTitle }}
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
