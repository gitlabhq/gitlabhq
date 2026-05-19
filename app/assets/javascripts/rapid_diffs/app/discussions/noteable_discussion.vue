<script>
import { getAutoSaveKeyFromDiscussion } from '~/lib/utils/autosave';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { ignoreWhilePending } from '~/lib/utils/ignore_while_pending';
import { s__, __, sprintf } from '~/locale';
import { detectAndConfirmSensitiveTokens } from '~/lib/utils/secret_detection';
import { createAlert } from '~/alert';
import { getNoteFormErrorMessages } from '~/notes/utils';
import DiscussionReplyPlaceholder from '~/notes/components/discussion_reply_placeholder.vue';
import ResolveDiscussionButton from '~/notes/components/resolve_discussion_button.vue';
import ResolveWithIssueButton from '~/notes/components/discussion_resolve_with_issue_button.vue';
import NoteSignedOutWidget from './note_signed_out_widget.vue';
import NoteForm from './note_form.vue';
import DiscussionNotes from './discussion_notes.vue';

export default {
  name: 'NoteableDiscussion',
  components: {
    DiscussionReplyPlaceholder,
    ResolveDiscussionButton,
    NoteSignedOutWidget,
    NoteForm,
    DiscussionNotes,
    ResolveWithIssueButton,
  },
  inject: {
    store: {
      type: Object,
    },
    userPermissions: {
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
    toggleResolveNote: {
      type: Function,
      required: false,
      default: null,
    },
    timelineLayout: {
      type: Boolean,
      required: false,
      default: false,
    },
    isLastDiscussion: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isLoggedIn: isLoggedIn(),
      isResolving: false,
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
    canReply() {
      return (
        !this.discussion.isDraft &&
        !this.discussion.notes[0]?.system &&
        !this.discussion.individual_note
      );
    },
    resolvable() {
      return this.discussion.resolvable;
    },
    canResolve() {
      return this.discussion.notes
        .filter((note) => note.resolvable)
        .every((note) => note.current_user?.can_resolve_discussion);
    },
    resolveButtonTitle() {
      return this.discussion.resolved ? __('Reopen thread') : __('Resolve thread');
    },
    hasDraftReply() {
      return this.discussion.notes.some((note) => note.isDraft);
    },
    canStartReview() {
      return Boolean(this.store.addDraftToDiscussion) && !this.hasDraftReply;
    },
    resolveWithIssuePath() {
      return !this.discussion.resolved ? this.discussion.resolve_with_issue_path : '';
    },
    showResolveDiscussionToggle() {
      return Boolean(this.toggleResolveNote) && this.resolvable && this.canResolve;
    },
  },
  methods: {
    async toggleResolve() {
      this.isResolving = true;
      try {
        await this.toggleResolveNote(this.discussion);
      } catch (error) {
        createAlert({
          message: __('Something went wrong while resolving this discussion. Please try again.'),
          error,
          captureError: true,
          parent: this.$el,
        });
      } finally {
        this.isResolving = false;
      }
    },
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
    async saveNote(noteText, shouldResolve) {
      if (!noteText) {
        this.cancelReplyForm();
        return;
      }

      const confirmSubmit = await detectAndConfirmSensitiveTokens({ content: noteText });

      if (!confirmSubmit) {
        return;
      }

      try {
        await this.store.replyToDiscussion(this.discussion, noteText);
        if (shouldResolve) {
          await this.toggleResolve();
        }
        this.$emit('stopReplying');
      } catch (e) {
        const message = getNoteFormErrorMessages(e.response)[0];
        createAlert({ message, parent: this.$el });
      }
    },
    async saveDraft(noteText, shouldResolve) {
      if (!noteText) {
        this.cancelReplyForm();
        return;
      }

      const confirmSubmit = await detectAndConfirmSensitiveTokens({ content: noteText });

      if (!confirmSubmit) {
        return;
      }

      try {
        await this.store.addDraftToDiscussion(this.discussion, noteText, shouldResolve);
        this.$emit('stopReplying');
      } catch (e) {
        const message = getNoteFormErrorMessages(e.response)[0];
        createAlert({ message, parent: this.$el });
      }
    },
  },
};
</script>

<template>
  <li
    class="js-discussion-container gl-@container/discussion"
    :data-discussion-id="discussion.id"
    :data-discussion-resolvable="resolvable || undefined"
    :data-discussion-resolved="discussion.resolved || undefined"
    data-testid="discussion-content"
  >
    <discussion-notes
      :notes="discussion.notes"
      :timeline-layout="timelineLayout"
      :expanded="discussion.repliesExpanded"
      :individual="discussion.individual_note"
      :is-last-discussion="isLastDiscussion"
      :can-resolve="Boolean(toggleResolveNote) && resolvable && canResolve"
      :is-resolved="discussion.resolved"
      :is-resolving="isResolving"
      @resolve="toggleResolve"
      @toggleDiscussionReplies="$emit('toggleDiscussionReplies')"
      @startReplying="showReplyForm"
      @noteEdited="$emit('noteEdited', $event)"
      @startEditing="$emit('startEditing', $event)"
      @cancelEditing="$emit('cancelEditing', $event)"
    >
      <template #avatar-badge>
        <slot name="avatar-badge"></slot>
      </template>
      <template #footer="{ hasReplies }">
        <div
          v-if="canReply"
          data-testid="reply-wrapper"
          class="gl-list-none gl-rounded-[var(--content-border-radius)] gl-border-t-subtle gl-bg-subtle gl-px-4 gl-py-4"
          :class="{ 'gl-border-t': !hasReplies, 'gl-pt-0': hasReplies }"
        >
          <div class="flash-container !gl-mt-0 gl-mb-2"></div>
          <note-signed-out-widget v-if="!isLoggedIn" />
          <note-form
            v-else-if="discussion.isReplying"
            ref="noteForm"
            :internal="discussion.internal"
            :save-button-title="saveButtonTitle"
            :save-note="saveNote"
            :save-draft="canStartReview ? saveDraft : null"
            :has-drafts="Boolean(store.hasDrafts)"
            :request-last-note-editing="() => requestLastNoteEditing(discussion)"
            :show-resolve-discussion-toggle="showResolveDiscussionToggle"
            :discussion-resolved="discussion.resolved"
            autofocus
            :autosave-key="autosaveKey"
            @cancel="cancelReplyForm"
          />
          <div v-else-if="userPermissions.can_create_note" class="gl-flex gl-flex-wrap gl-gap-4">
            <discussion-reply-placeholder
              class="gl-min-w-0 gl-flex-[9999] gl-basis-15"
              @focus="showReplyForm"
            />
            <div class="btn-group !gl-w-auto !gl-min-w-0 gl-flex-1 gl-basis-auto">
              <resolve-discussion-button
                v-if="toggleResolveNote && resolvable && canResolve"
                class="!gl-m-0"
                :is-resolving="isResolving"
                :button-title="resolveButtonTitle"
                @on-click="toggleResolve"
              />
              <resolve-with-issue-button
                v-if="discussion.resolvable && resolveWithIssuePath"
                :url="resolveWithIssuePath"
                class="!gl-w-auto"
              />
            </div>
          </div>
        </div>
      </template>
    </discussion-notes>
  </li>
</template>
