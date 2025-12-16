<script>
import axios from '~/lib/utils/axios_utils';
import { createAlert } from '~/alert';
import { getAutoSaveKeyFromDiscussion } from '~/lib/utils/autosave';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { ignoreWhilePending } from '~/lib/utils/ignore_while_pending';
import { s__, __, sprintf } from '~/locale';
import { detectAndConfirmSensitiveTokens } from '~/lib/utils/secret_detection';
import DiscussionReplyPlaceholder from '~/notes/components/discussion_reply_placeholder.vue';
import { createNoteErrorMessages } from '~/notes/utils';
import NoteSignedOutWidget from './note_signed_out_widget.vue';
import NoteForm from './note_form.vue';
import DiscussionNotes from './discussion_notes.vue';

export default {
  name: 'NoteableDiscussion',
  components: {
    DiscussionReplyPlaceholder,
    NoteSignedOutWidget,
    NoteForm,
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
    requestLastNoteEditing: {
      type: Function,
      required: true,
    },
  },
  data() {
    return {
      isLoggedIn: isLoggedIn(),
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
  },
  methods: {
    showReplyForm(text) {
      this.$emit('startReplying');
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

      this.$emit('stopReplying');
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
        const {
          data: { note },
        } = await axios.post(this.endpoints.createNote, postData);
        this.$emit('replyAdded', note);
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
        this.$emit('stopReplying');
      }
    },
  },
};
</script>

<template>
  <li
    class="js-discussion-container gl-@container/discussion"
    :data-discussion-id="discussion.id"
    data-testid="discussion-content"
  >
    <discussion-notes
      :notes="discussion.notes"
      :expanded="discussion.repliesExpanded"
      @toggleDiscussionReplies="$emit('toggleDiscussionReplies')"
      @startReplying="showReplyForm"
      @noteUpdated="$emit('noteUpdated', $event)"
      @noteDeleted="$emit('noteDeleted', $event)"
      @noteEdited="$emit('noteEdited', $event)"
      @startEditing="$emit('startEditing', $event)"
      @cancelEditing="$emit('cancelEditing', $event)"
      @toggleAward="$emit('toggleAward', $event)"
    >
      <template #avatar-badge>
        <slot name="avatar-badge"></slot>
      </template>
      <template #footer="{ hasReplies }">
        <li
          data-testid="reply-wrapper"
          class="gl-list-none gl-rounded-[var(--content-border-radius)] gl-border-t-subtle gl-bg-subtle gl-px-5 gl-py-4"
          :class="{ 'gl-border-t': !hasReplies, 'gl-pt-0': hasReplies }"
        >
          <div class="flash-container !gl-mt-0 gl-mb-2"></div>
          <note-signed-out-widget v-if="!isLoggedIn" />
          <note-form
            v-else-if="discussion.isReplying"
            ref="noteForm"
            :internal="discussion.internal"
            :save-button-title="saveButtonTitle"
            :save-note="saveReply"
            :request-last-note-editing="() => requestLastNoteEditing(discussion)"
            autofocus
            :autosave-key="autosaveKey"
            @cancel="cancelReplyForm"
          />
          <div v-else-if="userPermissions.can_create_note">
            <discussion-reply-placeholder @focus="showReplyForm" />
          </div>
        </li>
      </template>
    </discussion-notes>
  </li>
</template>
