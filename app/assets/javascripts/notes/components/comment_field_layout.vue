<script>
import NoteableWarning from '~/vue_shared/components/notes/noteable_warning.vue';
import EmailParticipantsWarning from './email_participants_warning.vue';

const DEFAULT_NOTEABLE_TYPE = 'Issue';

export default {
  components: {
    EmailParticipantsWarning,
    NoteableWarning,
  },
  props: {
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
  },
};
</script>
<template>
  <div
    class="comment-warning-wrapper gl-border-solid gl-border-1 gl-rounded-base gl-border-gray-100"
  >
    <div
      v-if="withAlertContainer"
      class="error-alert"
      data-testid="comment-field-alert-container"
    ></div>
    <noteable-warning
      v-if="hasWarning"
      class="gl-border-b-1 gl-border-b-solid gl-border-b-gray-100 gl-rounded-base gl-rounded-bottom-left-none gl-rounded-bottom-right-none"
      :is-locked="isLocked"
      :is-confidential="isConfidential"
      :noteable-type="noteableType"
      :locked-noteable-docs-path="noteableData.locked_discussion_docs_path"
      :confidential-noteable-docs-path="noteableData.confidential_issues_docs_path"
    />
    <slot></slot>
    <email-participants-warning
      v-if="emailParticipants.length"
      class="gl-border-t-1 gl-border-t-solid gl-border-t-gray-100 gl-rounded-base gl-rounded-top-left-none! gl-rounded-top-right-none!"
      :emails="emailParticipants"
    />
  </div>
</template>
