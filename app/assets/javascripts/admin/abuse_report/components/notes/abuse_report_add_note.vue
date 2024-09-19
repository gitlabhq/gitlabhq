<script>
import { sprintf, __ } from '~/locale';
import { createAlert } from '~/alert';
import { clearDraft } from '~/lib/utils/autosave';
import createNoteMutation from '../../graphql/notes/create_abuse_report_note.mutation.graphql';
import AbuseReportCommentForm from './abuse_report_comment_form.vue';

export default {
  name: 'AbuseReportAddNote',
  i18n: {
    reply: __('Reply…'),
    replyToComment: __('Reply to comment'),
    commentError: __('Comment could not be submitted: %{reason}.'),
    genericError: __(
      'Comment could not be submitted. Please check your network connection and try again.',
    ),
  },
  components: {
    AbuseReportCommentForm,
  },
  props: {
    abuseReportId: {
      type: String,
      required: true,
    },
    discussionId: {
      type: String,
      required: false,
      default: '',
    },
    isNewDiscussion: {
      type: Boolean,
      required: false,
      default: false,
    },
    showCommentForm: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isEditing: this.isNewDiscussion,
      isSubmitting: false,
    };
  },
  computed: {
    autosaveKey() {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      return this.discussionId ? `${this.discussionId}-comment` : `${this.abuseReportId}-comment`;
    },
    timelineEntryClasses() {
      return this.isNewDiscussion
        ? 'timeline-entry note-form'
        : // eslint-disable-next-line @gitlab/require-i18n-strings
          'note note-wrapper note-comment discussion-reply-holder !gl-border-t-0 clearfix';
    },
    timelineEntryInnerClasses() {
      return this.isNewDiscussion ? 'timeline-entry-inner' : '';
    },
    commentFormWrapperClasses() {
      return !this.isEditing ? 'gl-relative gl-flex gl-items-start gl-flex-nowrap' : '';
    },
    commentButtonText() {
      return this.isNewDiscussion ? __('Comment') : __('Reply');
    },
  },
  watch: {
    showCommentForm: {
      immediate: true,
      handler(focus) {
        if (focus) {
          this.isEditing = true;
        }
      },
    },
  },
  methods: {
    async addNote({ commentText }) {
      this.isSubmitting = true;

      this.$apollo
        .mutate({
          mutation: createNoteMutation,
          variables: {
            input: {
              abuseReportId: this.abuseReportId,
              body: commentText,
              discussionId: this.discussionId || null,
            },
          },
        })
        .then(() => {
          clearDraft(this.autosaveKey);
          this.cancelEditing();
        })
        .catch((error) => {
          const errorMessage = error?.message
            ? sprintf(this.$options.i18n.commentError, { reason: error.message.toLowerCase() })
            : this.$options.i18n.genericError;

          createAlert({
            message: errorMessage,
            parent: this.$el,
            captureError: true,
          });
        })
        .finally(() => {
          this.isSubmitting = false;
        });
    },
    cancelEditing() {
      this.isEditing = this.isNewDiscussion;
      this.$emit('cancelEditing');
    },
    showReplyForm() {
      this.isEditing = true;
    },
  },
};
</script>

<template>
  <li :class="timelineEntryClasses" data-testid="abuse-report-note-timeline-entry">
    <div :class="timelineEntryInnerClasses" data-testid="abuse-report-note-timeline-entry-inner">
      <div class="timeline-content">
        <div class="flash-container"></div>
        <div :class="commentFormWrapperClasses" data-testid="abuse-report-comment-form-wrapper">
          <abuse-report-comment-form
            v-if="isEditing"
            :abuse-report-id="abuseReportId"
            :is-submitting="isSubmitting"
            :autosave-key="autosaveKey"
            :comment-button-text="commentButtonText"
            @submitForm="addNote"
            @cancelEditing="cancelEditing"
          />
          <textarea
            v-else
            ref="textarea"
            rows="1"
            class="reply-placeholder-text-field"
            data-testid="abuse-report-note-reply-textarea"
            :placeholder="$options.i18n.reply"
            :aria-label="$options.i18n.replyToComment"
            @focus="showReplyForm"
            @click="showReplyForm"
          ></textarea>
        </div>
      </div>
    </div>
  </li>
</template>
