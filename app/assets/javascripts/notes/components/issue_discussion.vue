<script>
  /* global Flash */
  import { mapActions } from 'vuex';
  import { TOGGLE_DISCUSSION } from '../stores/mutation_types';
  import { SYSTEM_NOTE } from '../constants';
  import issueNote from './issue_note.vue';
  import userAvatarLink from '../../vue_shared/components/user_avatar/user_avatar_link.vue';
  import issueNoteHeader from './issue_note_header.vue';
  import issueNoteActions from './issue_note_actions.vue';
  import issueNoteSignedOutWidget from './issue_note_signed_out_widget.vue';
  import issueNoteEditedText from './issue_note_edited_text.vue';
  import issueNoteForm from './issue_note_form.vue';
  import placeholderNote from './issue_placeholder_note.vue';
  import placeholderSystemNote from './issue_placeholder_system_note.vue';

  export default {
    props: {
      note: {
        type: Object,
        required: true,
      },
    },
    data() {
      return {
        newNotePath: window.gl.issueData.create_note_path,
        isReplying: false,
      };
    },
    components: {
      issueNote,
      userAvatarLink,
      issueNoteHeader,
      issueNoteActions,
      issueNoteSignedOutWidget,
      issueNoteEditedText,
      issueNoteForm,
      placeholderNote,
      placeholderSystemNote,
    },
    computed: {
      discussion() {
        return this.note.notes[0];
      },
      author() {
        return this.discussion.author;
      },
      canReply() {
        return window.gl.issueData.current_user.can_create_note;
      },
    },
    methods: {
      ...mapActions([
        'saveNote',
      ]),
      ...mapMutations({
        toggleDiscussion: TOGGLE_DISCUSSION,
      }),
      componentName(note) {
        if (note.isPlaceholderNote) {
          if (note.placeholderType === SYSTEM_NOTE) {
            return placeholderSystemNote;
          }
          return placeholderNote;
        }

        return issueNote;
      },
      componentData(note) {
        return note.isPlaceholderNote ? note.notes[0] : note;
      },
      toggleDiscussion() {
        this.toggleDiscussion({ discussionId: this.note.id });
      },
      showReplyForm() {
        this.isReplying = true;
      },
      cancelReplyForm(shouldConfirm) {
        if (shouldConfirm && this.$refs.noteForm.isDirty) {
          const msg = 'Are you sure you want to cancel creating this comment?';
          // eslint-disable-next-line no-alert
          const isConfirmed = confirm(msg);
          if (!isConfirmed) {
            return;
          }
        }

        this.isReplying = false;
      },
      saveReply({ note }) {
        const replyData = {
          endpoint: this.newNotePath,
          flashContainer: this.$el,
          data: {
            in_reply_to_discussion_id: this.note.reply_id,
            target_type: 'issue',
            target_id: this.discussion.noteable_id,
            note: { note },
            full_data: true,
          },
        };

        this.saveNote(replyData)
          .then(() => {
            this.isReplying = false;
          })
          .catch(() => Flash('Something went wrong while adding your reply. Please try again.'));
      },
    },
  };
</script>

<template>
  <li class="note note-discussion timeline-entry">
    <div class="timeline-entry-inner">
      <div class="timeline-icon">
        <user-avatar-link
          :link-href="author.path"
          :img-src="author.avatar_url"
          :img-alt="author.name"
          :img-size="40"
          />
      </div>
      <div class="timeline-content">
        <div class="discussion">
          <div class="discussion-header">
            <issue-note-header
              :author="author"
              :created-at="discussion.created_at"
              :note-id="discussion.id"
              :include-toggle="true"
              :toggle-handler="toggleDiscussion"
              actionText="started a discussion"
              />
            <issue-note-edited-text
              v-if="note.last_updated_by"
              :edited-at="note.last_updated_at"
              :edited-by="note.last_updated_by"
              actionText="Last updated"
              className="discussion-headline-light js-discussion-headline" />
            </div>
          </div>
          <div
            v-if="note.expanded"
            class="discussion-body">
            <div class="panel panel-default">
              <div class="discussion-notes">
                <ul class="notes">
                  <component
                    v-for="note in note.notes"
                    :is="componentName(note)"
                    :note="componentData(note)"
                    key="note.id"
                    />
                </ul>
                <div class="flash-container"></div>
                <div class="discussion-reply-holder">
                  <button
                    v-if="canReply && !isReplying"
                    @click="showReplyForm"
                    type="button"
                    class="btn btn-text-field"
                    title="Add a reply">Reply...</button>
                  <issue-note-form
                    v-if="isReplying"
                    saveButtonTitle="Comment"
                    :update-handler="saveReply"
                    :cancel-handler="cancelReplyForm"
                    ref="noteForm"
                    />
                  <issue-note-signed-out-widget v-if="!canReply" />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </li>
</template>
