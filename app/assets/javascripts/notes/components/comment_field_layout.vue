<script>
import { s__ } from '~/locale';
import NoteableWarning from '~/vue_shared/components/notes/noteable_warning.vue';
import EmailParticipantsWarning from './email_participants_warning.vue';

const ATTACHMENT_REGEXP = /!?\[.*?\]\(\/uploads\/[0-9a-f]{32}\/.*?\)/;
const DEFAULT_NOTEABLE_TYPE = 'Issue';

export default {
  i18n: {
    attachmentWarning: s__(
      'Notes|Attachments are sent by email. Attachments over 10 MB are sent as links to your GitLab instance, and only accessible to project members.',
    ),
    confidentialAttachmentWarning: s__(
      'Notes|Uploaded files will be accessible to anyone with the file URL. Use caution when sharing file URLs.',
    ),
  },
  components: {
    EmailParticipantsWarning,
    NoteableWarning,
  },
  props: {
    isInternalNote: {
      type: Boolean,
      required: false,
      default: false,
    },
    note: {
      type: String,
      required: false,
      default: '',
    },
    noteableData: {
      type: Object,
      required: true,
    },
    noteableType: {
      type: String,
      required: false,
      default: DEFAULT_NOTEABLE_TYPE,
    },
    withAlertContainer: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    containsLink() {
      return ATTACHMENT_REGEXP.test(this.note);
    },
    isLocked() {
      return Boolean(this.noteableData.discussion_locked);
    },
    isConfidential() {
      return Boolean(this.noteableData.confidential);
    },
    hasWarningAbove() {
      return this.isConfidential || this.isLocked;
    },
    hasWarningBelow() {
      return (
        this.showConfidentialAttachmentWarning ||
        this.showAttachmentWarning ||
        this.showEmailParticipantsWarning
      );
    },
    emailParticipants() {
      return this.noteableData.issue_email_participants?.map(({ email }) => email) || [];
    },
    showEmailParticipantsWarning() {
      return this.emailParticipants.length && !this.isInternalNote;
    },
    showAttachmentWarning() {
      return this.showEmailParticipantsWarning && this.containsLink;
    },
    showConfidentialAttachmentWarning() {
      return (this.isConfidential || this.isInternalNote) && this.containsLink;
    },
  },
};
</script>
<template>
  <div class="comment-warning-wrapper">
    <div
      v-if="withAlertContainer"
      class="error-alert"
      data-testid="comment-field-alert-container"
    ></div>
    <noteable-warning
      v-if="hasWarningAbove"
      class="-gl-mb-3 gl-rounded-lg gl-rounded-b-none gl-pb-5 gl-pt-4"
      :is-locked="isLocked"
      :is-confidential="isConfidential"
      :noteable-type="noteableType"
      :locked-noteable-docs-path="noteableData.locked_discussion_docs_path"
      :confidential-noteable-docs-path="noteableData.confidential_issues_docs_path"
    />
    <slot></slot>
    <div
      v-if="hasWarningBelow"
      class="-gl-mt-3 gl-rounded-lg gl-rounded-t-none gl-bg-orange-50 gl-pb-1 gl-pt-4 gl-text-orange-600"
    >
      <div
        v-if="showConfidentialAttachmentWarning"
        class="gl-border-b gl-border-b-white gl-px-4 gl-py-2 last:gl-border-none"
      >
        {{ $options.i18n.confidentialAttachmentWarning }}
      </div>
      <div
        v-if="showAttachmentWarning"
        class="gl-border-b gl-border-b-white gl-px-4 gl-py-2 last:gl-border-none"
      >
        {{ $options.i18n.attachmentWarning }}
      </div>
      <email-participants-warning
        v-if="showEmailParticipantsWarning"
        class="gl-px-4 gl-py-2"
        :emails="emailParticipants"
      />
    </div>
  </div>
</template>
