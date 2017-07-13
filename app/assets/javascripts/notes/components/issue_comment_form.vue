<script>
/* global Flash */

import AjaxCache from '~/lib/utils/ajax_cache';
import UserAvatarLink from '../../vue_shared/components/user_avatar/user_avatar_link.vue';
import MarkdownField from '../../vue_shared/components/markdown/field.vue';
import IssueNoteSignedOutWidget from './issue_note_signed_out_widget.vue';
import eventHub from '../event_hub';

const REGEX_QUICK_ACTIONS = /^\/\w+.*$/gm;
export default {
  data() {
    const { create_note_path, state } = window.gl.issueData;
    const { currentUserData } = window.gl;

    return {
      note: '',
      markdownPreviewUrl: '',
      markdownDocsUrl: '',
      noteType: 'comment',
      issueState: state,
      endpoint: create_note_path,
      author: currentUserData,
    };
  },
  components: {
    UserAvatarLink,
    MarkdownField,
    IssueNoteSignedOutWidget,
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
  },
  methods: {
    handleSave(withIssueAction) {
      if (this.note.length) {
        const data = {
          endpoint: this.endpoint,
          noteData: {
            full_data: true,
            note: {
              noteable_type: 'Issue',
              noteable_id: window.gl.issueData.id,
              note: this.note,
            },
          },
        };

        if (this.noteType === 'discussion') {
          data.noteData.note.type = 'DiscussionNote';
        }

        let placeholderText = this.note;
        const hasQuickActions = this.hasQuickActions();

        if (hasQuickActions) {
          placeholderText = this.stripQuickActions();
        }

        if (placeholderText.length) {
          this.$store.commit('showPlaceholderNote', {
            noteBody: placeholderText,
          });
        }

        if (hasQuickActions) {
          this.$store.commit('showPlaceholderNote', {
            isSystemNote: true,
            noteBody: this.getQuickActionText(),
          });
        }

        this.$store.dispatch('createNewNote', data)
          .then((res) => {
            const { errors } = res;

            if (hasQuickActions) {
              this.$store.dispatch('poll');
              $(this.$refs.textarea).trigger('clear-commands-cache.atwho');
              new Flash('Commands applied', 'notice', $(this.$el)); // eslint-disable-line
            }

            if (errors) {
              if (errors.commands_only) {
                new Flash(errors.commands_only, 'notice', $(this.$el)); // eslint-disable-line
                this.discard();
              } else {
                this.handleError();
              }
            } else {
              this.discard();
            }

            this.$store.commit('removePlaceholderNotes');
          })
          .catch(this.handleError);
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
    discard() {
      // `blur` is needed to clear slash commands autocomplete cache if event fired.
      // `focus` is needed to remain cursor in the textarea.
      this.$refs.textarea.blur();
      this.$refs.textarea.focus();
      this.note = '';
    },
    setNoteType(type) {
      this.noteType = type;
    },
    handleError() {
      new Flash('Something went wrong while adding your comment. Please try again.'); // eslint-disable-line
    },
    editMyLastNote() {
      if (this.note === '') {
        const myLastNoteId = $('.js-my-note').last().attr('id');

        if (myLastNoteId) {
          eventHub.$emit('EnterEditMode', {
            noteId: parseInt(myLastNoteId.replace('note_', ''), 10),
          });
        }
      }
    },
    getQuickActionText() {
      let text = 'Applying command';
      const quickActions = AjaxCache.get(gl.GfmAutoComplete.dataSources.commands);
      const { note } = this;

      const executedCommands = quickActions.filter((command) => {
        const commandRegex = new RegExp(`/${command.name}`);
        return commandRegex.test(note);
      });

      if (executedCommands && executedCommands.length) {
        if (executedCommands.length > 1) {
          text = 'Applying multiple commands';
        } else {
          const commandDescription = executedCommands[0].description.toLowerCase();
          text = `Applying command to ${commandDescription}`;
        }
      }

      return text;
    },
    hasQuickActions() {
      return REGEX_QUICK_ACTIONS.test(this.note);
    },
    stripQuickActions() {
      return this.note.replace(REGEX_QUICK_ACTIONS, '').trim();
    },
  },
  mounted() {
    const issuableDataEl = document.getElementById('js-issuable-app-initial-data');
    const issueData = JSON.parse(issuableDataEl.innerHTML.replace(/&quot;/g, '"'));
    const { markdownDocs, markdownPreviewUrl } = issueData;

    this.markdownDocsUrl = markdownDocs;
    this.markdownPreviewUrl = markdownPreviewUrl;

    eventHub.$on('IssueStateChanged', (isClosed) => {
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
              :linkHref="author.path"
              :imgSrc="author.avatar_url"
              :imgAlt="author.name"
              :imgSize="40" />
          </div>
          <div class="js-main-target-form timeline-content timeline-content-form common-note-form">
            <markdown-field
              :markdown-preview-url="markdownPreviewUrl"
              :markdown-docs="markdownDocsUrl"
              :addSpacingClasses="false">
              <textarea
                id="note-body"
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
            <div class="note-form-actions clearfix">
              <div class="pull-left btn-group append-right-10 comment-type-dropdown js-comment-type-dropdown">
                <input
                  @click="handleSave()"
                  :disabled="!note.length"
                  :value="commentButtonTitle"
                  class="btn btn-nr btn-create comment-btn js-comment-button js-comment-submit-button"
                  type="submit" />
                <button
                  :disabled="!note.length"
                  name="button"
                  type="button"
                  class="btn btn-nr comment-btn note-type-toggle js-note-new-discussion"
                  data-toggle="dropdown"
                  aria-label="Open comment type dropdown">
                  <i
                    aria-hidden="true"
                    class="fa fa-caret-down toggle-icon"></i>
                </button>
                <ul
                  class="dropdown-menu note-type-dropdown dropdown-open-top">
                  <li
                    :class="{ 'item-selected': noteType === 'comment' }"
                    @click.prevent="setNoteType('comment')">
                    <a href="#">
                      <i
                        aria-hidden="true"
                        class="fa fa-check"></i>
                      <div class="description">
                        <strong>Comment</strong>
                        <p>
                          Add a general comment to this issue.
                        </p>
                      </div>
                    </a>
                  </li>
                  <li class="divider"></li>
                  <li
                    :class="{ 'item-selected': noteType === 'discussion' }"
                    @click.prevent="setNoteType('discussion')">
                    <a href="#">
                      <i
                        aria-hidden="true"
                        class="fa fa-check"></i>
                      <div class="description">
                        <strong>Start discussion</strong>
                        <p>
                          Discuss a specific suggestion or question.
                        </p>
                      </div>
                    </a>
                  </li>
                </ul>
              </div>
              <a
                @click="handleSave(true)"
                :class="{'btn-reopen': !isIssueOpen, 'btn-close': isIssueOpen}"
                class="btn btn-nr btn-comment">
                {{issueActionButtonTitle}}
              </a>
              <a
                v-if="note.length"
                @click="discard"
                class="btn btn-cancel js-note-discard"
                role="button">
                Discard draft
              </a>
            </div>
          </div>
        </div>
      </li>
    </ul>
  </div>
</template>
