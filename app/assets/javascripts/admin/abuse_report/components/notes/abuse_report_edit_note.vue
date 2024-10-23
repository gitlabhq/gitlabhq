<script>
import { sprintf, __ } from '~/locale';
import { createAlert } from '~/alert';
import { clearDraft } from '~/lib/utils/autosave';
import updateNoteMutation from '../../graphql/notes/update_abuse_report_note.mutation.graphql';

import AbuseReportCommentForm from './abuse_report_comment_form.vue';

export default {
  name: 'AbuseReportEditNote',
  i18n: {
    updateError: __('Comment could not be updated: %{reason}.'),
    genericError: __('Something went wrong while editing your comment. Please try again.'),
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
    note: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isSubmitting: false,
    };
  },
  computed: {
    autosaveKey() {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      return `${this.note.id}-comment`;
    },
    commentButtonText() {
      return __('Save comment');
    },
  },
  methods: {
    handleErrorResponse(error) {
      const errorMessage = error?.message
        ? sprintf(this.$options.i18n.updateError, { reason: error.message.toLowerCase() })
        : this.$options.i18n.genericError;

      createAlert({
        message: errorMessage,
        parent: this.$el,
        captureError: true,
      });
    },

    async updateNote({ commentText }) {
      this.isSubmitting = true;

      this.$apollo
        .mutate({
          mutation: updateNoteMutation,
          variables: {
            input: {
              id: this.note.id,
              body: commentText,
            },
          },
        })
        .then(({ data }) => {
          const { note, errors } = data.updateAbuseReportNote;
          clearDraft(this.autosaveKey);
          if (errors.length) {
            this.handleErrorResponse({
              message: errors.join('. '),
            });
          } else {
            this.$emit('updateNote', note);
          }
        })
        .catch((error) => {
          this.handleErrorResponse(error);
        })
        .finally(() => {
          this.isSubmitting = false;
        });
    },
  },
};
</script>

<template>
  <div>
    <div class="flash-container"></div>
    <abuse-report-comment-form
      :abuse-report-id="abuseReportId"
      :initial-value="note.body"
      :is-submitting="isSubmitting"
      :autosave-key="autosaveKey"
      :comment-button-text="commentButtonText"
      class="gl-mt-3 gl-pl-3"
      @submitForm="updateNote"
      @cancelEditing="$emit('cancelEditing')"
    />
  </div>
</template>
