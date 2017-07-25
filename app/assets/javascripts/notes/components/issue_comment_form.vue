<script>
/* global Flash */

import userAvatarLink from '../../vue_shared/components/user_avatar/user_avatar_link.vue';
import markdownField from '../../vue_shared/components/markdown/field.vue';
import issueNoteSignedOutWidget from './issue_note_signed_out_widget.vue';
import eventHub from '../event_hub';

export default {
  data() {
    const { create_note_path, state } = window.gl.issueData;
    const { currentUserData } = window.gl;

    return {
      note: '',
      markdownDocsUrl: '',
      markdownPreviewUrl: gl.issueData.preview_note_path,
      noteType: 'comment',
      issueState: state,
      endpoint: create_note_path,
      author: currentUserData,
    };
  },
  components: {
    userAvatarLink,
    markdownField,
    issueNoteSignedOutWidget,
  },
  computed: {
    isLoggedIn() {
      return window.gon.current_user_id;
    },
    commentButtonTitle() {
      return this.noteType === 'comment' ? 'Comment' : 'Start discussion';
    },
    isIssueOpen() {
      return this.issueState === 'opened' || this.issueState === 'reopened';
    },
    issueActionButtonTitle() {
      if (this.note.length) {
        const actionText = this.isIssueOpen ? 'close' : 'reopen';

        return this.noteType === 'comment' ? `Comment & ${actionText} issue` : `Start discussion & ${actionText} issue`;
      }

      return this.isIssueOpen ? 'Close issue' : 'Reopen issue';
    },
    actionButtonClassNames() {
      return {
        'btn-reopen': !this.isIssueOpen,
        'btn-close': this.isIssueOpen,
        'js-note-target-close': this.isIssueOpen,
        'js-note-target-reopen': !this.isIssueOpen,
      };
    },
    canUpdateIssue() {
      const { issueData } = window.gl;
      return issueData && issueData.current_user.can_update;
    },
  },
  methods: {
    handleSave(withIssueAction) {
      if (this.note.length) {
        const noteData = {
          endpoint: this.endpoint,
          flashContainer: this.$el,
          data: {
            full_data: true,
            note: {
              noteable_type: 'Issue',
              noteable_id: window.gl.issueData.id,
              note: this.note,
            },
          },
        };

        if (this.noteType === 'discussion') {
          noteData.data.note.type = 'DiscussionNote';
        }

        this.$store.dispatch('saveNote', noteData)
          .then((res) => {
            if (res.errors) {
              if (res.errors.commands_only) {
                this.discard();
              } else {
                this.handleError();
              }
            } else {
              this.discard();
            }
          })
          .catch(() => {
            this.discard(false);
          });
      }

      if (withIssueAction) {
        if (this.isIssueOpen) {
          gl.issueData.state = 'closed';
          this.issueState = 'closed';
        } else {
          gl.issueData.state = 'reopened';
          this.issueState = 'reopened';
        }
        this.isIssueOpen = !this.isIssueOpen;

        // This is out of scope for the Notes Vue component.
        // It was the shortest path to update the issue state and relevant places.
        const btnClass = this.isIssueOpen ? 'btn-reopen' : 'btn-close';
        $(`.js-btn-issue-action.${btnClass}:visible`).trigger('click');
      }
    },
    discard(shouldClear = true) {
      // `blur` is needed to clear slash commands autocomplete cache if event fired.
      // `focus` is needed to remain cursor in the textarea.
      this.$refs.textarea.blur();
      this.$refs.textarea.focus();

      if (shouldClear) {
        this.note = '';
      }
    },
    setNoteType(type) {
      this.noteType = type;
    },
    handleError() {
      Flash('Something went wrong while adding your comment. Please try again.');
    },
    editMyLastNote() {
      if (this.note === '') {
        const myLastNoteId = $('.js-my-note').last().attr('id');

        if (myLastNoteId) {
          eventHub.$emit('enterEditMode', {
            noteId: parseInt(myLastNoteId.replace('note_', ''), 10),
          });
        }
      }
    },
  },
  mounted() {
    const issuableDataEl = document.getElementById('js-issuable-app-initial-data');
    const issueData = JSON.parse(issuableDataEl.innerHTML.replace(/&quot;/g, '"'));

    this.markdownDocsUrl = issueData.markdownDocs;

    eventHub.$on('issueStateChanged', (isClosed) => {
      this.issueState = isClosed ? 'closed' : 'reopened';
    });
  },
};
</script>

<template>
  <div>
    <issue-note-signed-out-widget v-if="!isLoggedIn" />
    <ul
      v-if="isLoggedIn"
      class="notes notes-form timeline new-note">
      <li class="timeline-entry">
        <div class="timeline-entry-inner">
          <div class="flash-container timeline-content"></div>
          <div class="timeline-icon hidden-xs hidden-sm">
            <user-avatar-link
              v-if="author"
              :link-href="author.path"
              :img-src="author.avatar_url"
              :img-alt="author.name"
              :img-size="40" />
          </div>
          <div class="js-main-target-form timeline-content timeline-content-form common-note-form">
            <markdown-field
              :markdown-preview-url="markdownPreviewUrl"
              :markdown-docs="markdownDocsUrl"
              :addSpacingClasses="false">
              <textarea
                id="note-body"
                name="note[note]"
                class="note-textarea js-gfm-input js-autosize markdown-area"
                data-supports-slash-commands="true"
                data-supports-quick-actions="true"
                aria-label="Description"
                v-model="note"
                ref="textarea"
                slot="textarea"
                placeholder="Write a comment or drag your files here..."
                @keydown.up="editMyLastNote"
                @keydown.meta.enter="handleSave()">
              </textarea>
            </markdown-field>
            <div class="note-form-actions">
              <div class="pull-left btn-group append-right-10 comment-type-dropdown js-comment-type-dropdown droplab-dropdown">
                <button
                  @click="handleSave()"
                  :disabled="!note.length"
                  class="btn btn-nr btn-create comment-btn js-comment-button js-comment-submit-button"
                  type="button">
                  {{commentButtonTitle}}
                </button>
                <button
                  :disabled="!note.length"
                  name="button"
                  type="button"
                  class="btn btn-nr comment-btn note-type-toggle js-note-new-discussion dropdown-toggle"
                  data-toggle="dropdown"
                  aria-label="Open comment type dropdown">
                  <i
                    aria-hidden="true"
                    class="fa fa-caret-down toggle-icon"></i>
                </button>
                <ul class="note-type-dropdown dropdown-open-top dropdown-menu">
                  <li
                    :class="{ 'droplab-item-selected': noteType === 'comment' }"
                    @click.prevent="setNoteType('comment')">
                    <button
                      type="button"
                      class="btn btn-transparent">
                      <i
                        aria-hidden="true"
                        class="fa fa-check icon"></i>
                      <div class="description">
                        <strong>Comment</strong>
                        <p>
                          Add a general comment to this issue.
                        </p>
                      </div>
                    </button>
                  </li>
                  <li class="divider droplab-item-ignore"></li>
                  <li
                    :class="{ 'droplab-item-selected': noteType === 'discussion' }"
                    @click.prevent="setNoteType('discussion')">
                    <button
                      type="button"
                      class="btn btn-transparent">
                      <i
                        aria-hidden="true"
                        class="fa fa-check icon">
                        </i>
                      <div class="description">
                        <strong>Start discussion</strong>
                        <p>
                          Discuss a specific suggestion or question.
                        </p>
                      </div>
                    </button>
                  </li>
                </ul>
              </div>
              <button
                type="button"
                @click="handleSave(true)"
                v-if="canUpdateIssue"
                :class="actionButtonClassNames"
                class="btn btn-nr btn-comment btn-comment-and-close">
                {{issueActionButtonTitle}}
              </button>
              <button
                type="button"
                v-if="note.length"
                @click="discard"
                class="btn btn-cancel js-note-discard">
                Discard draft
              </button>
            </div>
          </div>
        </div>
      </li>
    </ul>
  </div>
</template>
