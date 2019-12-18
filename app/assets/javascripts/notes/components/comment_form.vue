<script>
import $ from 'jquery';
import { mapActions, mapGetters, mapState } from 'vuex';
import _ from 'underscore';
import Autosize from 'autosize';
import { __, sprintf } from '~/locale';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import Flash from '../../flash';
import Autosave from '../../autosave';
import {
  capitalizeFirstCharacter,
  convertToCamelCase,
  splitCamelCase,
  slugifyWithUnderscore,
} from '../../lib/utils/text_utility';
import { refreshUserMergeRequestCounts } from '~/commons/nav/user_merge_requests';
import * as constants from '../constants';
import eventHub from '../event_hub';
import issueWarning from '../../vue_shared/components/issue/issue_warning.vue';
import markdownField from '../../vue_shared/components/markdown/field.vue';
import userAvatarLink from '../../vue_shared/components/user_avatar/user_avatar_link.vue';
import loadingButton from '../../vue_shared/components/loading_button.vue';
import noteSignedOutWidget from './note_signed_out_widget.vue';
import discussionLockedWidget from './discussion_locked_widget.vue';
import issuableStateMixin from '../mixins/issuable_state';

export default {
  name: 'CommentForm',
  components: {
    issueWarning,
    noteSignedOutWidget,
    discussionLockedWidget,
    markdownField,
    userAvatarLink,
    loadingButton,
    TimelineEntryItem,
  },
  mixins: [issuableStateMixin],
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
      isSubmitting: false,
      isSubmitButtonDisabled: true,
    };
  },
  computed: {
    ...mapGetters([
      'getCurrentUserLastNote',
      'getUserData',
      'getNoteableData',
      'getNotesData',
      'openState',
    ]),
    ...mapState(['isToggleStateButtonLoading']),
    noteableDisplayName() {
      return splitCamelCase(this.noteableType).toLowerCase();
    },
    isLoggedIn() {
      return this.getUserData.id;
    },
    commentButtonTitle() {
      return this.noteType === constants.COMMENT ? __('Comment') : __('Start thread');
    },
    startDiscussionDescription() {
      return this.getNoteableData.noteableType === constants.MERGE_REQUEST_NOTEABLE_TYPE
        ? __('Discuss a specific suggestion or question that needs to be resolved.')
        : __('Discuss a specific suggestion or question.');
    },
    isOpen() {
      return this.openState === constants.OPENED || this.openState === constants.REOPENED;
    },
    canCreateNote() {
      return this.getNoteableData.current_user.can_create_note;
    },
    issueActionButtonTitle() {
      const openOrClose = this.isOpen ? 'close' : 'reopen';

      if (this.note.length) {
        return sprintf(__('%{actionText} & %{openOrClose} %{noteable}'), {
          actionText: this.commentButtonTitle,
          openOrClose,
          noteable: this.noteableDisplayName,
        });
      }

      return sprintf(__('%{openOrClose} %{noteable}'), {
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
        this.getNoteableData.state !== constants.MERGED
      );
    },
    endpoint() {
      return this.getNoteableData.create_note_path;
    },
    issuableTypeTitle() {
      return this.noteableType === constants.MERGE_REQUEST_NOTEABLE_TYPE
        ? __('merge request')
        : __('issue');
    },
    trackingLabel() {
      return slugifyWithUnderscore(`${this.commentButtonTitle} button`);
    },
  },
  watch: {
    note(newNote) {
      this.setIsSubmitButtonDisabled(newNote, this.isSubmitting);
    },
    isSubmitting(newValue) {
      this.setIsSubmitButtonDisabled(this.note, newValue);
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
      'closeIssue',
      'reopenIssue',
      'toggleIssueLocalState',
      'toggleStateButtonLoading',
    ]),
    setIsSubmitButtonDisabled(note, isSubmitting) {
      if (!_.isEmpty(note) && !isSubmitting) {
        this.isSubmitButtonDisabled = false;
      } else {
        this.isSubmitButtonDisabled = true;
      }
    },
    handleSave(withIssueAction) {
      this.isSubmitting = true;

      if (this.note.length) {
        const noteData = {
          endpoint: this.endpoint,
          flashContainer: this.$el,
          data: {
            note: {
              noteable_type: this.noteableType,
              noteable_id: this.getNoteableData.id,
              note: this.note,
            },
            merge_request_diff_head_sha: this.getNoteableData.diff_head_sha,
          },
        };

        if (this.noteType === constants.DISCUSSION) {
          noteData.data.note.type = constants.DISCUSSION_NOTE;
        }

        this.note = ''; // Empty textarea while being requested. Repopulate in catch
        this.resizeTextarea();
        this.stopPolling();

        this.saveNote(noteData)
          .then(() => {
            this.enableButton();
            this.restartPolling();
            this.discard();

            if (withIssueAction) {
              this.toggleIssueState();
            }
          })
          .catch(() => {
            this.enableButton();
            this.discard(false);
            const msg = __(
              'Your comment could not be submitted! Please check your network connection and try again.',
            );
            Flash(msg, 'alert', this.$el);
            this.note = noteData.data.note.note; // Restore textarea content.
            this.removePlaceholderNotes();
          });
      } else {
        this.toggleIssueState();
      }
    },
    enableButton() {
      this.isSubmitting = false;
    },
    toggleIssueState() {
      if (this.isOpen) {
        this.closeIssue()
          .then(() => {
            this.enableButton();
            refreshUserMergeRequestCounts();
          })
          .catch(() => {
            this.enableButton();
            this.toggleStateButtonLoading(false);
            Flash(
              sprintf(
                __('Something went wrong while closing the %{issuable}. Please try again later'),
                { issuable: this.noteableDisplayName },
              ),
            );
          });
      } else {
        this.reopenIssue()
          .then(() => {
            this.enableButton();
            refreshUserMergeRequestCounts();
          })
          .catch(({ data }) => {
            this.enableButton();
            this.toggleStateButtonLoading(false);
            let errorMessage = sprintf(
              __('Something went wrong while reopening the %{issuable}. Please try again later'),
              { issuable: this.noteableDisplayName },
            );

            if (data) {
              errorMessage = Object.values(data).join('\n');
            }

            Flash(errorMessage);
          });
      }
    },
    discard(shouldClear = true) {
      // `blur` is needed to clear slash commands autocomplete cache if event fired.
      // `focus` is needed to remain cursor in the textarea.
      this.$refs.textarea.blur();
      this.$refs.textarea.focus();

      if (shouldClear) {
        this.note = '';
        this.resizeTextarea();
        this.$refs.markdownField.previewMarkdown = false;
      }

      this.autosave.reset();
    },
    setNoteType(type) {
      this.noteType = type;
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
          __('Note'),
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
  },
};
</script>

<template>
  <div>
    <note-signed-out-widget v-if="!isLoggedIn" />
    <discussion-locked-widget v-else-if="!canCreateNote" :issuable-type="issuableTypeTitle" />
    <ul v-else-if="canCreateNote" class="notes notes-form timeline">
      <timeline-entry-item class="note-form">
        <div class="flash-container error-alert timeline-content"></div>
        <div class="timeline-icon d-none d-sm-none d-md-block">
          <user-avatar-link
            v-if="author"
            :link-href="author.path"
            :img-src="author.avatar_url"
            :img-alt="author.name"
            :img-size="40"
          />
        </div>
        <div class="timeline-content timeline-content-form">
          <form ref="commentForm" class="new-note common-note-form gfm-form js-main-target-form">
            <div class="error-alert"></div>

            <issue-warning
              v-if="hasWarning(getNoteableData)"
              :is-locked="isLocked(getNoteableData)"
              :is-confidential="isConfidential(getNoteableData)"
              :locked-issue-docs-path="lockedIssueDocsPath"
              :confidential-issue-docs-path="confidentialIssueDocsPath"
            />

            <markdown-field
              ref="markdownField"
              :is-submitting="isSubmitting"
              :markdown-preview-path="markdownPreviewPath"
              :markdown-docs-path="markdownDocsPath"
              :quick-actions-docs-path="quickActionsDocsPath"
              :add-spacing-classes="false"
            >
              <textarea
                id="note-body"
                ref="textarea"
                slot="textarea"
                v-model="note"
                dir="auto"
                :disabled="isSubmitting"
                name="note[note]"
                class="note-textarea js-vue-comment-form js-note-text
js-gfm-input js-autosize markdown-area js-vue-textarea qa-comment-input"
                data-supports-quick-actions="true"
                :aria-label="__('Description')"
                :placeholder="__('Write a comment or drag your files here…')"
                @keydown.up="editCurrentUserLastNote()"
                @keydown.meta.enter="handleSave()"
                @keydown.ctrl.enter="handleSave()"
              >
              </textarea>
            </markdown-field>
            <div class="note-form-actions">
              <div
                class="float-left btn-group
append-right-10 comment-type-dropdown js-comment-type-dropdown droplab-dropdown"
              >
                <button
                  :disabled="isSubmitButtonDisabled"
                  class="btn btn-success js-comment-button js-comment-submit-button
                    qa-comment-button"
                  type="submit"
                  :data-track-label="trackingLabel"
                  data-track-event="click_button"
                  @click.prevent="handleSave()"
                >
                  {{ commentButtonTitle }}
                </button>
                <button
                  :disabled="isSubmitButtonDisabled"
                  name="button"
                  type="button"
                  class="btn btn-success note-type-toggle js-note-new-discussion dropdown-toggle qa-note-dropdown"
                  data-display="static"
                  data-toggle="dropdown"
                  :aria-label="__('Open comment type dropdown')"
                >
                  <i aria-hidden="true" class="fa fa-caret-down toggle-icon"> </i>
                </button>

                <ul class="note-type-dropdown dropdown-open-top dropdown-menu">
                  <li :class="{ 'droplab-item-selected': noteType === 'comment' }">
                    <button
                      type="button"
                      class="btn btn-transparent"
                      @click.prevent="setNoteType('comment')"
                    >
                      <i aria-hidden="true" class="fa fa-check icon"> </i>
                      <div class="description">
                        <strong>{{ __('Comment') }}</strong>
                        <p>
                          {{
                            sprintf(__('Add a general comment to this %{noteableDisplayName}.'), {
                              noteableDisplayName,
                            })
                          }}
                        </p>
                      </div>
                    </button>
                  </li>
                  <li class="divider droplab-item-ignore"></li>
                  <li :class="{ 'droplab-item-selected': noteType === 'discussion' }">
                    <button
                      type="button"
                      class="btn btn-transparent qa-discussion-option"
                      @click.prevent="setNoteType('discussion')"
                    >
                      <i aria-hidden="true" class="fa fa-check icon"> </i>
                      <div class="description">
                        <strong>{{ __('Start thread') }}</strong>
                        <p>{{ startDiscussionDescription }}</p>
                      </div>
                    </button>
                  </li>
                </ul>
              </div>

              <loading-button
                v-if="canToggleIssueState"
                :loading="isToggleStateButtonLoading"
                :container-class="[
                  actionButtonClassNames,
                  'btn btn-comment btn-comment-and-close js-action-button',
                ]"
                :disabled="isToggleStateButtonLoading || isSubmitting"
                :label="issueActionButtonTitle"
                @click="handleSave(true)"
              />
            </div>
          </form>
        </div>
      </timeline-entry-item>
    </ul>
  </div>
</template>
