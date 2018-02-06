<script>
  import { mapActions, mapGetters } from 'vuex';
  import Flash from '../../flash';
  import { SYSTEM_NOTE } from '../constants';
  import userAvatarLink from '../../vue_shared/components/user_avatar/user_avatar_link.vue';
  import noteableNote from './noteable_note.vue';
  import noteHeader from './note_header.vue';
  import noteSignedOutWidget from './note_signed_out_widget.vue';
  import noteEditedText from './note_edited_text.vue';
  import noteForm from './note_form.vue';
  import placeholderNote from '../../vue_shared/components/notes/placeholder_note.vue';
  import placeholderSystemNote from '../../vue_shared/components/notes/placeholder_system_note.vue';
  import autosave from '../mixins/autosave';

  export default {
    components: {
      noteableNote,
      userAvatarLink,
      noteHeader,
      noteSignedOutWidget,
      noteEditedText,
      noteForm,
      placeholderNote,
      placeholderSystemNote,
    },
    mixins: [
      autosave,
    ],
    props: {
      note: {
        type: Object,
        required: true,
      },
    },
    data() {
      return {
        isReplying: false,
      };
    },
    computed: {
      ...mapGetters([
        'getNoteableData',
      ]),
      discussion() {
        return this.note.notes[0];
      },
      author() {
        return this.discussion.author;
      },
      canReply() {
        return this.getNoteableData.current_user.can_create_note;
      },
      newNotePath() {
        return this.getNoteableData.create_note_path;
      },
      lastUpdatedBy() {
        const { notes } = this.note;

        if (notes.length > 1) {
          return notes[notes.length - 1].author;
        }

        return null;
      },
      lastUpdatedAt() {
        const { notes } = this.note;

        if (notes.length > 1) {
          return notes[notes.length - 1].created_at;
        }

        return null;
      },
    },
    mounted() {
      if (this.isReplying) {
        this.initAutoSave();
      }
    },
    updated() {
      if (this.isReplying) {
        if (!this.autosave) {
          this.initAutoSave();
        } else {
          this.setAutoSave();
        }
      }
    },
    methods: {
      ...mapActions([
        'saveNote',
        'toggleDiscussion',
        'removePlaceholderNotes',
      ]),
      componentName(note) {
        if (note.isPlaceholderNote) {
          if (note.placeholderType === SYSTEM_NOTE) {
            return placeholderSystemNote;
          }
          return placeholderNote;
        }

        return noteableNote;
      },
      componentData(note) {
        return note.isPlaceholderNote ? note.notes[0] : note;
      },
      toggleDiscussionHandler() {
        this.toggleDiscussion({ discussionId: this.note.id });
      },
      showReplyForm() {
        this.isReplying = true;
      },
      cancelReplyForm(shouldConfirm) {
        if (shouldConfirm && this.$refs.noteForm.isDirty) {
          // eslint-disable-next-line no-alert
          if (!confirm('Are you sure you want to cancel creating this comment?')) {
            return;
          }
        }

        this.resetAutoSave();
        this.isReplying = false;
      },
      saveReply(noteText, form, callback) {
        const replyData = {
          endpoint: this.newNotePath,
          flashContainer: this.$el,
          data: {
            in_reply_to_discussion_id: this.note.reply_id,
            target_type: 'issue',
            target_id: this.discussion.noteable_id,
            note: { note: noteText },
          },
        };
        this.isReplying = false;

        this.saveNote(replyData)
          .then(() => {
            this.resetAutoSave();
            callback();
          })
          .catch((err) => {
            this.removePlaceholderNotes();
            this.isReplying = true;
            this.$nextTick(() => {
              const msg = `Your comment could not be submitted!
Please check your network connection and try again.`;
              Flash(msg, 'alert', this.$el);
              this.$refs.noteForm.note = noteText;
              callback(err);
            });
          });
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
            <note-header
              :author="author"
              :created-at="discussion.created_at"
              :note-id="discussion.id"
              :include-toggle="true"
              @toggleHandler="toggleDiscussionHandler"
              action-text="started a discussion"
              class="discussion"
            />
            <note-edited-text
              v-if="lastUpdatedAt"
              :edited-at="lastUpdatedAt"
              :edited-by="lastUpdatedBy"
              action-text="Last updated"
              class-name="discussion-headline-light js-discussion-headline"
            />
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
                  :key="note.id"
                />
              </ul>
              <div
                :class="{ 'is-replying': isReplying }"
                class="discussion-reply-holder">
                <button
                  v-if="canReply && !isReplying"
                  @click="showReplyForm"
                  type="button"
                  class="js-vue-discussion-reply btn btn-text-field"
                  title="Add a reply">
                  Reply...
                </button>
                <note-form
                  v-if="isReplying"
                  save-button-title="Comment"
                  :discussion="note"
                  :is-editing="false"
                  @handleFormUpdate="saveReply"
                  @cancelFormEdition="cancelReplyForm"
                  ref="noteForm"
                />
                <note-signed-out-widget v-if="!canReply" />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </li>
</template>
