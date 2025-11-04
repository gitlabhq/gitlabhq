<script>
import { createAlert } from '~/alert';
import { getAutoSaveKeyFromDiscussion } from '~/lib/utils/autosave';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { ignoreWhilePending } from '~/lib/utils/ignore_while_pending';
import { s__, __, sprintf } from '~/locale';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import { detectAndConfirmSensitiveTokens } from '~/lib/utils/secret_detection';
import DiscussionReplyPlaceholder from '~/notes/components/discussion_reply_placeholder.vue';
import { createNoteErrorMessages } from '~/notes/utils';
import DiscussionNotes from '~/notes/components/discussion_notes.vue';
import NoteForm from '~/notes/components/note_form.vue';
import NoteSignedOutWidget from '~/notes/components/note_signed_out_widget.vue';

export default {
  name: 'NoteableDiscussion',
  components: {
    DiscussionReplyPlaceholder,
    NoteSignedOutWidget,
    NoteForm,
    TimelineEntryItem,
    DiscussionNotes,
  },
  inject: {
    userPermissions: {
      type: Object,
    },
    endpoints: {
      type: Object,
    },
  },
  props: {
    discussion: {
      type: Object,
      required: true,
    },
    saveNote: {
      type: Function,
      required: true,
    },
  },
  data() {
    return {
      isLoggedIn: isLoggedIn(),
      isReplying: false,
    };
  },
  computed: {
    commentType() {
      return this.discussion.internal ? __('internal note') : __('comment');
    },
    autosaveKey() {
      return getAutoSaveKeyFromDiscussion(this.discussion);
    },
    saveButtonTitle() {
      return this.discussion.internal ? __('Reply internally') : __('Reply');
    },
    isDiscussionInternal() {
      return this.discussion.notes[0]?.internal;
    },
    discussionHolderClass() {
      return {
        'is-replying': this.isReplying,
        'internal-note': this.isDiscussionInternal,
      };
    },
  },
  methods: {
    showReplyForm(text) {
      this.$emit('showReplyForm');
      this.isReplying = true;
      if (typeof text !== 'undefined') {
        this.$nextTick(() => {
          this.$refs.noteForm.append(text);
        });
      }
    },
    cancelReplyForm: ignoreWhilePending(async function cancelReplyForm(shouldConfirm, isDirty) {
      if (shouldConfirm && isDirty) {
        const msg = sprintf(
          s__('Notes|Are you sure you want to cancel creating this %{commentType}?'),
          { commentType: this.commentType },
        );

        const confirmed = await confirmAction(msg, {
          primaryBtnText: __('Discard changes'),
          cancelBtnText: __('Continue editing'),
        });

        if (!confirmed) {
          return;
        }
      }

      this.isReplying = false;
    }),
    async saveReply(noteText) {
      if (!noteText) {
        this.cancelReplyForm();
        return;
      }

      const confirmSubmit = await detectAndConfirmSensitiveTokens({ content: noteText });

      if (!confirmSubmit) {
        return;
      }

      const postData = {
        in_reply_to_discussion_id: this.discussion.reply_id,
        // TODO: should be implied on the endpoint level
        // target_type: this.getNoteableData.targetType,
        note: { note: noteText },
      };

      // TODO: should be implied on the endpoint level
      // if (this.discussion.for_commit) {
      //   postData.note_project_id = this.discussion.project_id;
      // }

      try {
        // TODO: fix after we support adding discussions
        await this.saveNote(this.endpoints.createNote, postData);
      } catch (error) {
        if (error.response) {
          const errorMessage = createNoteErrorMessages(
            error.response.data,
            error.response.status,
          )[0];
          createAlert({
            message: errorMessage,
            parent: this.$el,
          });
        }
        throw error;
      } finally {
        this.isReplying = false;
      }
    },
  },
};
</script>

<template>
  <timeline-entry-item class="note note-discussion">
    <div class="timeline-content">
      <div
        :data-discussion-id="discussion.id"
        class="discussion js-discussion-container"
        data-testid="discussion-content"
      >
        <div class="discussion-body">
          <div class="card discussion-wrapper">
            <discussion-notes
              :discussion="discussion"
              @toggleDiscussionReplies="$emit('toggleDiscussionReplies')"
              @startReplying="showReplyForm"
            >
              <template #avatar-badge>
                <slot name="avatar-badge"></slot>
              </template>
              <template #footer="{ showReplies }">
                <li
                  v-if="showReplies"
                  data-testid="reply-wrapper"
                  class="discussion-reply-holder gl-bg-subtle gl-clearfix"
                  :class="discussionHolderClass"
                >
                  <div class="flash-container !gl-mt-0 gl-mb-2"></div>
                  <note-signed-out-widget v-if="!isLoggedIn" />
                  <note-form
                    v-else-if="isReplying"
                    ref="noteForm"
                    :discussion="discussion"
                    :save-button-title="saveButtonTitle"
                    :save-note="saveReply"
                    autofocus
                    :autosave-key="autosaveKey"
                    @cancelForm="cancelReplyForm"
                  />
                  <div
                    v-else-if="userPermissions.can_create_note"
                    class="discussion-with-resolve-btn gl-clearfix"
                  >
                    <discussion-reply-placeholder @focus="showReplyForm" />
                  </div>
                </li>
              </template>
            </discussion-notes>
          </div>
        </div>
      </div>
    </div>
  </timeline-entry-item>
</template>
