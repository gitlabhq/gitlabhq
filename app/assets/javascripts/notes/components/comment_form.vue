<script>
import {
  GlAlert,
  GlButton,
  GlIcon,
  GlFormCheckbox,
  GlTooltipDirective,
  GlDropdown,
  GlDropdownItem,
  GlDropdownDivider,
} from '@gitlab/ui';
import Autosize from 'autosize';
import $ from 'jquery';
import { mapActions, mapGetters, mapState } from 'vuex';
import Autosave from '~/autosave';
import { refreshUserMergeRequestCounts } from '~/commons/nav/user_merge_requests';
import createFlash from '~/flash';
import { statusBoxState } from '~/issuable/components/status_box.vue';
import httpStatusCodes from '~/lib/utils/http_status';
import {
  capitalizeFirstCharacter,
  convertToCamelCase,
  splitCamelCase,
  slugifyWithUnderscore,
} from '~/lib/utils/text_utility';
import { sprintf } from '~/locale';
import markdownField from '~/vue_shared/components/markdown/field.vue';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

import * as constants from '../constants';
import eventHub from '../event_hub';
import { COMMENT_FORM } from '../i18n';

import issuableStateMixin from '../mixins/issuable_state';
import CommentFieldLayout from './comment_field_layout.vue';
import discussionLockedWidget from './discussion_locked_widget.vue';
import noteSignedOutWidget from './note_signed_out_widget.vue';

const { UNPROCESSABLE_ENTITY } = httpStatusCodes;

export default {
  name: 'CommentForm',
  i18n: COMMENT_FORM,
  noteTypeComment: constants.COMMENT,
  noteTypeDiscussion: constants.DISCUSSION,
  components: {
    noteSignedOutWidget,
    discussionLockedWidget,
    markdownField,
    GlAlert,
    GlButton,
    TimelineEntryItem,
    GlIcon,
    CommentFieldLayout,
    GlFormCheckbox,
    GlDropdown,
    GlDropdownItem,
    GlDropdownDivider,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagsMixin(), issuableStateMixin],
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
      noteIsConfidential: false,
      isSubmitting: false,
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
    isNoteTypeComment() {
      return this.noteType === constants.COMMENT;
    },
    isNoteTypeDiscussion() {
      return this.noteType === constants.DISCUSSION;
    },
    noteableDisplayName() {
      return splitCamelCase(this.noteableType).toLowerCase();
    },
    isLoggedIn() {
      return this.getUserData.id;
    },
    commentButtonTitle() {
      return this.noteType === constants.COMMENT
        ? this.$options.i18n.comment
        : this.$options.i18n.startThread;
    },
    startDiscussionDescription() {
      return this.getNoteableData.noteableType === constants.MERGE_REQUEST_NOTEABLE_TYPE
        ? this.$options.i18n.discussionThatNeedsResolution
        : this.$options.i18n.discussion;
    },
    commentDescription() {
      return sprintf(this.$options.i18n.submitButton.commentHelp, {
        noteableDisplayName: this.noteableDisplayName,
      });
    },
    isOpen() {
      return this.openState === constants.OPENED || this.openState === constants.REOPENED;
    },
    canCreateNote() {
      return this.getNoteableData.current_user.can_create_note;
    },
    canSetConfidential() {
      return this.getNoteableData.current_user.can_update;
    },
    issueActionButtonTitle() {
      const openOrClose = this.isOpen ? 'close' : 'reopen';

      if (this.note.length) {
        return sprintf(this.$options.i18n.actionButtonWithNote, {
          actionText: this.commentButtonTitle,
          openOrClose,
          noteable: this.noteableDisplayName,
        });
      }

      return sprintf(this.$options.i18n.actionButton, {
        openOrClose: capitalizeFirstCharacter(openOrClose),
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
    quickActionsDocsPath() {
      return this.getNotesData.quickActionsDocsPath;
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
        this.openState !== constants.MERGED &&
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
    issuableTypeTitle() {
      return this.noteableType === constants.MERGE_REQUEST_NOTEABLE_TYPE
        ? this.$options.i18n.mergeRequest
        : this.$options.i18n.issue;
    },
    isIssue() {
      return this.noteableDisplayName === constants.ISSUE_NOTEABLE_TYPE;
    },
    trackingLabel() {
      return slugifyWithUnderscore(`${this.commentButtonTitle} button`);
    },
    confidentialNotesEnabled() {
      return Boolean(this.glFeatures.confidentialNotes);
    },
    disableSubmitButton() {
      return this.note.length === 0 || this.isSubmitting;
    },
  },
  mounted() {
    // jQuery is needed here because it is a custom event being dispatched with jQuery.
    $(document).on('issuable:change', (e, isClosed) => {
      this.toggleIssueLocalState(isClosed ? constants.CLOSED : constants.REOPENED);
    });

    this.initAutoSave();
  },
  methods: {
    ...mapActions([
      'saveNote',
      'stopPolling',
      'restartPolling',
      'removePlaceholderNotes',
      'closeIssuable',
      'reopenIssuable',
      'toggleIssueLocalState',
    ]),
    handleSaveError({ data, status }) {
      if (status === UNPROCESSABLE_ENTITY && data.errors?.commands_only?.length) {
        this.errors = data.errors.commands_only;
      } else {
        this.errors = [this.$options.i18n.GENERIC_UNSUBMITTABLE_NETWORK];
      }
    },
    handleSaveDraft() {
      this.handleSave({ isDraft: true });
    },
    handleSave({ withIssueAction = false, isDraft = false } = {}) {
      this.errors = [];

      if (this.note.length) {
        const noteData = {
          endpoint: isDraft ? this.draftEndpoint : this.endpoint,
          data: {
            note: {
              noteable_type: this.noteableType,
              noteable_id: this.getNoteableData.id,
              confidential: this.noteIsConfidential,
              note: this.note,
            },
            merge_request_diff_head_sha: this.getNoteableData.diff_head_sha,
          },
          isDraft,
        };

        if (this.noteType === constants.DISCUSSION) {
          noteData.data.note.type = constants.DISCUSSION_NOTE;
        }

        this.note = ''; // Empty textarea while being requested. Repopulate in catch
        this.resizeTextarea();
        this.stopPolling();

        this.isSubmitting = true;

        this.saveNote(noteData)
          .then(() => {
            this.restartPolling();
            this.discard();

            if (withIssueAction) {
              this.toggleIssueState();
            }
          })
          .catch(({ response }) => {
            this.handleSaveError(response);

            this.discard(false);
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
        .then(() => statusBoxState.updateStatus && statusBoxState.updateStatus())
        .then(refreshUserMergeRequestCounts)
        .catch(() =>
          createFlash({
            message: constants.toggleStateErrorMessage[this.noteableType][this.openState],
          }),
        );
    },
    discard(shouldClear = true) {
      // `blur` is needed to clear slash commands autocomplete cache if event fired.
      // `focus` is needed to remain cursor in the textarea.
      this.$refs.textarea.blur();
      this.$refs.textarea.focus();

      if (shouldClear) {
        this.note = '';
        this.noteIsConfidential = false;
        this.resizeTextarea();
        this.$refs.markdownField.previewMarkdown = false;
      }

      this.autosave.reset();
    },
    setNoteType(type) {
      this.noteType = type;
    },
    setNoteTypeToComment() {
      this.setNoteType(constants.COMMENT);
    },
    setNoteTypeToDiscussion() {
      this.setNoteType(constants.DISCUSSION);
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
    initAutoSave() {
      if (this.isLoggedIn) {
        const noteableType = capitalizeFirstCharacter(convertToCamelCase(this.noteableType));

        this.autosave = new Autosave($(this.$refs.textarea), [
          this.$options.i18n.note,
          noteableType,
          this.getNoteableData.id,
        ]);
      }
    },
    resizeTextarea() {
      this.$nextTick(() => {
        Autosize.update(this.$refs.textarea);
      });
    },
    hasEmailParticipants() {
      return this.getNoteableData.issue_email_participants?.length;
    },
    dismissError(index) {
      this.errors.splice(index, 1);
    },
  },
};
</script>

<template>
  <div>
    <note-signed-out-widget v-if="!isLoggedIn" />
    <discussion-locked-widget v-else-if="!canCreateNote" :issuable-type="issuableTypeTitle" />
    <ul v-else-if="canCreateNote" class="notes notes-form timeline">
      <timeline-entry-item class="note-form">
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
          <form ref="commentForm" class="new-note common-note-form gfm-form js-main-target-form">
            <comment-field-layout
              :with-alert-container="true"
              :noteable-data="getNoteableData"
              :noteable-type="noteableType"
            >
              <markdown-field
                ref="markdownField"
                :is-submitting="isSubmitting"
                :markdown-preview-path="markdownPreviewPath"
                :markdown-docs-path="markdownDocsPath"
                :quick-actions-docs-path="quickActionsDocsPath"
                :add-spacing-classes="false"
                :textarea-value="note"
              >
                <template #textarea>
                  <textarea
                    id="note-body"
                    ref="textarea"
                    v-model="note"
                    dir="auto"
                    :disabled="isSubmitting"
                    name="note[note]"
                    class="note-textarea js-vue-comment-form js-note-text js-gfm-input js-autosize markdown-area"
                    data-qa-selector="comment_field"
                    data-testid="comment-field"
                    :data-supports-quick-actions="!glFeatures.tributeAutocomplete"
                    :aria-label="$options.i18n.comment"
                    :placeholder="$options.i18n.bodyPlaceholder"
                    @keydown.up="editCurrentUserLastNote()"
                    @keydown.meta.enter="handleEnter()"
                    @keydown.ctrl.enter="handleEnter()"
                  ></textarea>
                </template>
              </markdown-field>
            </comment-field-layout>
            <div class="note-form-actions">
              <template v-if="hasDrafts">
                <gl-button
                  :disabled="disableSubmitButton"
                  data-testid="add-to-review-button"
                  type="submit"
                  category="primary"
                  variant="success"
                  @click.prevent="handleSaveDraft()"
                  >{{ __('Add to review') }}</gl-button
                >
                <gl-button
                  :disabled="disableSubmitButton"
                  data-testid="add-comment-now-button"
                  category="secondary"
                  @click.prevent="handleSave()"
                  >{{ __('Add comment now') }}</gl-button
                >
              </template>
              <template v-else>
                <gl-form-checkbox
                  v-if="confidentialNotesEnabled && canSetConfidential"
                  v-model="noteIsConfidential"
                  class="gl-mb-6"
                  data-testid="confidential-note-checkbox"
                >
                  {{ $options.i18n.confidential }}
                  <gl-icon
                    v-gl-tooltip:tooltipcontainer.bottom
                    name="question"
                    :size="16"
                    :title="$options.i18n.confidentialVisibility"
                    class="gl-text-gray-500"
                  />
                </gl-form-checkbox>
                <gl-dropdown
                  split
                  :text="commentButtonTitle"
                  class="gl-mr-3 js-comment-button js-comment-submit-button comment-type-dropdown"
                  category="primary"
                  variant="confirm"
                  :disabled="disableSubmitButton"
                  data-testid="comment-button"
                  data-qa-selector="comment_button"
                  :data-track-label="trackingLabel"
                  data-track-event="click_button"
                  @click="handleSave()"
                >
                  <gl-dropdown-item
                    is-check-item
                    :is-checked="isNoteTypeComment"
                    :selected="isNoteTypeComment"
                    @click="setNoteTypeToComment"
                  >
                    <strong>{{ $options.i18n.submitButton.comment }}</strong>
                    <p class="gl-m-0">{{ commentDescription }}</p>
                  </gl-dropdown-item>
                  <gl-dropdown-divider />
                  <gl-dropdown-item
                    is-check-item
                    :is-checked="isNoteTypeDiscussion"
                    :selected="isNoteTypeDiscussion"
                    data-qa-selector="discussion_menu_item"
                    @click="setNoteTypeToDiscussion"
                  >
                    <strong>{{ $options.i18n.submitButton.startThread }}</strong>
                    <p class="gl-m-0">{{ startDiscussionDescription }}</p>
                  </gl-dropdown-item>
                </gl-dropdown>
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
