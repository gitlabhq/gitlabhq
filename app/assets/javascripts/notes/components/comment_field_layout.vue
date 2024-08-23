<script>
import NoteableWarning from '~/vue_shared/components/notes/noteable_warning.vue';
import EmailParticipantsWarning from './email_participants_warning.vue';
import AttachmentsWarning from './attachments_warning.vue';

const DEFAULT_NOTEABLE_TYPE = 'Issue';

export default {
  components: {
    AttachmentsWarning,
    EmailParticipantsWarning,
    NoteableWarning,
  },
  props: {
    noteableData: {
      type: Object,
      required: true,
    },
    isInternalNote: {
      type: Boolean,
      required: false,
      default: false,
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
    containsLink: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    isLocked() {
      return Boolean(this.noteableData.discussion_locked);
    },
    isConfidential() {
      return Boolean(this.noteableData.confidential);
    },
    hasWarning() {
      return this.isConfidential || this.isLocked;
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
      v-if="hasWarning"
      class="-gl-mb-3 gl-rounded-lg gl-rounded-bl-none gl-rounded-br-none gl-pb-5 gl-pt-4"
      :is-locked="isLocked"
      :is-confidential="isConfidential"
      :noteable-type="noteableType"
      :locked-noteable-docs-path="noteableData.locked_discussion_docs_path"
      :confidential-noteable-docs-path="noteableData.confidential_issues_docs_path"
    />
    <slot></slot>
    <attachments-warning
      v-if="showAttachmentWarning"
      :class="{
        'gl-py-3': !showEmailParticipantsWarning,
        '-gl-mt-3 gl-pb-3 gl-pt-4': showEmailParticipantsWarning,
      }"
    />
    <email-participants-warning
      v-if="showEmailParticipantsWarning"
      class="gl-rounded-lg !gl-rounded-tl-none !gl-rounded-tr-none gl-border-t-1"
      :class="{
        '-gl-mt-3 gl-pb-3 gl-pt-4': !showAttachmentWarning,
        'gl-mt-1 gl-py-3': showAttachmentWarning,
      }"
      :emails="emailParticipants"
    />
  </div>
</template>
