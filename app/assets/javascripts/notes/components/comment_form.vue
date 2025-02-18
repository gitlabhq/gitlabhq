<script>
import { GlAlert, GlButton, GlFormCheckbox, GlTooltipDirective } from '@gitlab/ui';
import $ from 'jquery';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapGetters, mapState } from 'vuex';
import { createAlert } from '~/alert';
import { STATUS_CLOSED, STATUS_MERGED, STATUS_OPEN, STATUS_REOPENED } from '~/issues/constants';
import { detectAndConfirmSensitiveTokens } from '~/lib/utils/secret_detection';
import {
  capitalizeFirstCharacter,
  convertToCamelCase,
  slugifyWithUnderscore,
} from '~/lib/utils/text_utility';
import { sprintf } from '~/locale';
import { InternalEvents } from '~/tracking';
import { badgeState } from '~/merge_requests/components/merge_request_header.vue';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';
import { trackSavedUsingEditor } from '~/vue_shared/components/markdown/tracking';
import glAbilitiesMixin from '~/vue_shared/mixins/gl_abilities_mixin';
import { fetchUserCounts } from '~/super_sidebar/user_counts_fetch';

import * as constants from '../constants';
import eventHub from '../event_hub';
import { COMMENT_FORM } from '../i18n';
import { createNoteErrorMessages, isSlashCommand } from '../utils';

import issuableStateMixin from '../mixins/issuable_state';
import CommentFieldLayout from './comment_field_layout.vue';
import CommentTypeDropdown from './comment_type_dropdown.vue';
import DiscussionLockedWidget from './discussion_locked_widget.vue';
import NoteSignedOutWidget from './note_signed_out_widget.vue';

export default {
  name: 'CommentForm',
  i18n: COMMENT_FORM,
  components: {
    NoteSignedOutWidget,
    DiscussionLockedWidget,
    MarkdownEditor,
    GlAlert,
    GlButton,
    TimelineEntryItem,
    HelpIcon,
    CommentFieldLayout,
    CommentTypeDropdown,
    GlFormCheckbox,
    CommentTemperature: () =>
      import(
        /* webpackChunkName: 'comment_temperature' */ 'ee_component/ai/components/comment_temperature.vue'
      ),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [issuableStateMixin, InternalEvents.mixin(), glAbilitiesMixin()],
  props: {
    noteableType: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      note: '',
      noteType: constants.COMMENT,
      errors: [],
      noteIsInternal: false,
      isSubmitting: false,
      isMeasuringCommentTemperature: false,
      formFieldProps: {
        'aria-label': this.$options.i18n.comment,
        placeholder: this.$options.i18n.bodyPlaceholder,
        id: 'note-body',
        name: 'note[note]',
        class: 'js-note-text note-textarea js-gfm-input markdown-area',
        'data-testid': 'comment-field',
      },
    };
  },
  computed: {
    ...mapGetters([
      'getCurrentUserLastNote',
      'getUserData',
      'getNoteableData',
      'getNoteableDataByProp',
      'getNotesData',
      'openState',
      'hasDrafts',
    ]),
    ...mapState(['isToggleStateButtonLoading']),
    autocompleteDataSources() {
      return gl.GfmAutoComplete?.dataSources;
    },
    noteableDisplayName() {
      const displayNameMap = {
        [constants.ISSUE_NOTEABLE_TYPE]: this.$options.i18n.issue,
        [constants.EPIC_NOTEABLE_TYPE]: this.$options.i18n.epic,
        [constants.MERGE_REQUEST_NOTEABLE_TYPE]: this.$options.i18n.mergeRequest,
      };

      const noteableTypeKey =
        constants.NOTEABLE_TYPE_MAPPING[this.noteableType] || constants.ISSUE_NOTEABLE_TYPE;
      return displayNameMap[noteableTypeKey];
    },
    isLoggedIn() {
      return this.getUserData.id;
    },
    commentButtonTitle() {
      const { comment, internalComment, startThread, startInternalThread } = this.$options.i18n;
      if (this.noteIsInternal) {
        return this.noteType === constants.COMMENT ? internalComment : startInternalThread;
      }
      return this.noteType === constants.COMMENT ? comment : startThread;
    },
    discussionsRequireResolution() {
      return this.getNoteableData.noteableType === constants.MERGE_REQUEST_NOTEABLE_TYPE;
    },
    isOpen() {
      return this.openState === STATUS_OPEN || this.openState === STATUS_REOPENED;
    },
    canCreateNote() {
      return this.getNoteableData.current_user.can_create_note;
    },
    canSetInternalNote() {
      return this.getNoteableData.current_user.can_create_confidential_note;
    },
    issueActionButtonTitle() {
      const openOrClose = this.isOpen ? 'close' : 'reopen';

      if (this.note.length) {
        return sprintf(this.$options.i18n.actionButton.withNote[openOrClose], {
          actionText: this.commentButtonTitle,
          noteable: this.noteableDisplayName,
        });
      }

      return sprintf(this.$options.i18n.actionButton.withoutNote[openOrClose], {
        noteable: this.noteableDisplayName,
      });
    },
    actionButtonClassNames() {
      return {
        'btn-reopen': !this.isOpen,
        'btn-close': this.isOpen,
        'js-note-target-close': this.isOpen,
        'js-note-target-reopen': !this.isOpen,
      };
    },
    markdownDocsPath() {
      return this.getNotesData.markdownDocsPath;
    },
    markdownPreviewPath() {
      return this.getNoteableData.preview_note_path;
    },
    author() {
      return this.getUserData;
    },
    canToggleIssueState() {
      return (
        this.getNoteableData.current_user.can_update &&
        this.openState !== STATUS_MERGED &&
        !this.closedAndLocked
      );
    },
    closedAndLocked() {
      return !this.isOpen && this.isLocked(this.getNoteableData);
    },
    endpoint() {
      return this.getNoteableData.create_note_path;
    },
    draftEndpoint() {
      return this.getNotesData.draftsPath;
    },
    isIssue() {
      return constants.NOTEABLE_TYPE_MAPPING[this.noteableType] === constants.ISSUE_NOTEABLE_TYPE;
    },
    isEpic() {
      return constants.NOTEABLE_TYPE_MAPPING[this.noteableType] === constants.EPIC_NOTEABLE_TYPE;
    },
    isMergeRequest() {
      return (
        constants.NOTEABLE_TYPE_MAPPING[this.noteableType] === constants.MERGE_REQUEST_NOTEABLE_TYPE
      );
    },
    trackingLabel() {
      return slugifyWithUnderscore(`${this.commentButtonTitle} button`);
    },
    disableSubmitButton() {
      return this.note.length === 0 || this.isSubmitting;
    },
    autosaveKey() {
      if (this.isLoggedIn) {
        const noteableType = capitalizeFirstCharacter(convertToCamelCase(this.noteableType));
        return `${this.$options.i18n.note}/${noteableType}/${this.getNoteableData.id}`;
      }

      return null;
    },
    shouldDisableField() {
      return this.isSubmitting && !this.isMeasuringCommentTemperature;
    },
    shouldMeasureNoteTemperature() {
      return !isSlashCommand(this.note) && this.glAbilities.measureCommentTemperature;
    },
  },
  watch: {
    noteIsInternal(val) {
      this.formFieldProps.placeholder = val
        ? this.$options.i18n.bodyPlaceholderInternal
        : this.$options.i18n.bodyPlaceholder;
    },
  },
  mounted() {
    // jQuery is needed here because it is a custom event being dispatched with jQuery.
    $(document).on('issuable:change', (e, isClosed) => {
      this.toggleIssueLocalState(isClosed ? STATUS_CLOSED : STATUS_REOPENED);
    });
  },
  methods: {
    ...mapActions([
      'saveNote',
      'removePlaceholderNotes',
      'closeIssuable',
      'reopenIssuable',
      'toggleIssueLocalState',
    ]),
    handleSaveError({ data, status }) {
      this.errors = createNoteErrorMessages(data, status);
    },
    handleSaveDraft() {
      this.handleSave({ isDraft: true });
    },
    async handleSave({
      withIssueAction = false,
      isDraft = false,
      shouldMeasureTemperature = true,
    } = {}) {
      this.errors = [];

      if (this.note.length) {
        const noteData = {
          endpoint: isDraft ? this.draftEndpoint : this.endpoint,
          flashContainer: this.$el,
          data: {
            note: {
              noteable_type: this.noteableType,
              noteable_id: this.getNoteableData.id,
              internal: this.noteIsInternal,
              note: this.note,
            },
            merge_request_diff_head_sha: this.getNoteableData.diff_head_sha,
          },
          isDraft,
        };

        if (this.noteType === constants.DISCUSSION || isDraft) {
          noteData.data.note.type = constants.DISCUSSION_NOTE;
        }

        const confirmSubmit = await detectAndConfirmSensitiveTokens({ content: this.note });
        if (!confirmSubmit) {
          return;
        }

        this.isSubmitting = true;

        if (this.shouldMeasureNoteTemperature && shouldMeasureTemperature) {
          this.saveNoteParams = { isDraft, withIssueAction };
          this.isMeasuringCommentTemperature = true;
          this.$refs.commentTemperature.measureCommentTemperature();
          return;
        }

        if (!this.shouldMeasureTemperature) {
          this.isMeasuringCommentTemperature = false;
        }

        this.note = ''; // Empty textarea while being requested. Repopulate in catch
        if (isDraft) {
          eventHub.$emit('noteFormAddToReview', { name: 'noteFormAddToReview' });
        }

        trackSavedUsingEditor(
          this.$refs.markdownEditor.isContentEditorActive,
          `${this.noteableType}_${this.noteType}`,
        );

        this.saveNote(noteData)
          .then(() => {
            this.discard();

            if (withIssueAction) {
              this.toggleIssueState();
            }
          })
          .catch(({ response }) => {
            this.handleSaveError(response);

            this.note = noteData.data.note.note; // Restore textarea content.
            this.removePlaceholderNotes();
          })
          .finally(() => {
            this.isSubmitting = false;
          });
      } else {
        this.toggleIssueState();
      }
    },
    handleEnter() {
      if (this.hasDrafts) {
        this.handleSaveDraft();
      } else {
        this.handleSave();
      }
    },
    toggleIssueState() {
      if (this.isIssue) {
        // We want to invoke the close/reopen logic in the issue header
        // since that is where the blocked-by issues modal logic is also defined
        eventHub.$emit('toggle.issuable.state');
        return;
      }

      const toggleState = this.isOpen ? this.closeIssuable : this.reopenIssuable;

      toggleState()
        .then(() => {
          fetchUserCounts();
          // badgeState is only initialized for MR type
          // To avoid undefined error added an optional chaining to function
          return badgeState?.updateStatus?.();
        })
        .catch(() =>
          createAlert({
            message: constants.toggleStateErrorMessage[this.noteableType][this.openState],
          }),
        );
    },
    discard() {
      this.note = '';
      this.noteIsInternal = false;
      this.$refs.markdownEditor.togglePreview(false);
    },
    editCurrentUserLastNote() {
      if (this.note === '') {
        const lastNote = this.getCurrentUserLastNote;

        if (lastNote) {
          eventHub.$emit('enterEditMode', {
            noteId: lastNote.id,
          });
        }
      }
    },
    hasEmailParticipants() {
      return this.getNoteableData.issue_email_participants?.length;
    },
    dismissError(index) {
      this.errors.splice(index, 1);
    },
    onInput(value) {
      this.note = value;
    },
    append(value) {
      this.$refs.markdownEditor.append(value);
    },
  },
};
</script>

<template>
  <div>
    <note-signed-out-widget v-if="!isLoggedIn" />
    <discussion-locked-widget v-else-if="!canCreateNote" :issuable-type="noteableDisplayName" />
    <ul v-else-if="canCreateNote" class="notes notes-form timeline">
      <timeline-entry-item class="note-form">
        <div class="flash-container gl-mb-2"></div>
        <gl-alert
          v-for="(error, index) in errors"
          :key="index"
          variant="danger"
          class="gl-mb-2"
          @dismiss="() => dismissError(index)"
        >
          {{ error }}
        </gl-alert>
        <div class="timeline-content timeline-content-form">
          <form
            ref="commentForm"
            class="new-note common-note-form gfm-form js-main-target-form"
            data-testid="comment-form"
            @submit.stop.prevent
          >
            <comment-field-layout
              :with-alert-container="true"
              :is-internal-note="noteIsInternal"
              :note="note"
              :noteable-data="getNoteableData"
              :noteable-type="noteableType"
            >
              <markdown-editor
                ref="markdownEditor"
                :value="note"
                :render-markdown-path="markdownPreviewPath"
                :markdown-docs-path="markdownDocsPath"
                :add-spacing-classes="false"
                :form-field-props="formFieldProps"
                :autosave-key="autosaveKey"
                :disabled="shouldDisableField"
                :autocomplete-data-sources="autocompleteDataSources"
                :noteable-type="noteableType"
                supports-quick-actions
                @keydown.up="editCurrentUserLastNote()"
                @keydown.shift.meta.enter="handleSave()"
                @keydown.shift.ctrl.enter="handleSave()"
                @keydown.meta.enter.exact="handleEnter()"
                @keydown.ctrl.enter.exact="handleEnter()"
                @input="onInput"
              />
            </comment-field-layout>
            <comment-temperature
              v-if="glAbilities.measureCommentTemperature"
              ref="commentTemperature"
              v-model="note"
              :item-id="getNoteableData.id"
              :item-type="noteableType"
              :user-id="getUserData.id"
              @save="handleSave({ ...saveNoteParams, shouldMeasureTemperature: false })"
            />
            <div class="note-form-actions gl-flex gl-flex-wrap gl-gap-3">
              <gl-form-checkbox
                v-if="canSetInternalNote"
                v-model="noteIsInternal"
                class="gl-basis-full"
                data-testid="internal-note-checkbox"
              >
                {{ $options.i18n.internal }}
                <help-icon
                  v-gl-tooltip:tooltipcontainer.bottom
                  :title="$options.i18n.internalVisibility"
                />
              </gl-form-checkbox>
              <template v-if="hasDrafts">
                <gl-button
                  :disabled="disableSubmitButton"
                  data-testid="add-to-review-button"
                  category="primary"
                  variant="confirm"
                  @click="handleSaveDraft()"
                >
                  {{ $options.i18n.addToReview }}
                </gl-button>
                <gl-button
                  :disabled="disableSubmitButton"
                  data-testid="add-comment-now-button"
                  category="secondary"
                  @click.prevent="handleSave()"
                  >{{ $options.i18n.addCommentNow }}</gl-button
                >
              </template>
              <template v-else>
                <comment-type-dropdown
                  v-model="noteType"
                  data-testid="comment-button"
                  :disabled="disableSubmitButton"
                  :tracking-label="trackingLabel"
                  :is-internal-note="noteIsInternal"
                  :noteable-display-name="noteableDisplayName"
                  :discussions-require-resolution="discussionsRequireResolution"
                  class="!gl-mb-0"
                  @click="handleSave"
                />
                <template v-if="isMergeRequest">
                  <gl-button
                    :disabled="disableSubmitButton"
                    data-testid="start-review-button"
                    category="secondary"
                    variant="confirm"
                    @click="handleSaveDraft()"
                  >
                    {{ $options.i18n.startReview }}
                  </gl-button>
                </template>
              </template>
              <gl-button
                v-if="canToggleIssueState"
                :loading="isToggleStateButtonLoading"
                :class="[actionButtonClassNames, 'btn-comment btn-comment-and-close']"
                :disabled="isSubmitting"
                data-testid="close-reopen-button"
                @click="handleSave({ withIssueAction: true })"
                >{{ issueActionButtonTitle }}</gl-button
              >
            </div>
          </form>
        </div>
      </timeline-entry-item>
    </ul>
  </div>
</template>
