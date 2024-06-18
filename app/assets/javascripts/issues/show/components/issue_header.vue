<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { STATUS_OPEN, STATUS_REOPENED, WORKSPACE_PROJECT } from '~/issues/constants';
import { __, s__ } from '~/locale';
import IssuableHeader from '~/vue_shared/issuable/show/components/issuable_header.vue';

export default {
  WORKSPACE_PROJECT,
  components: {
    GlLink,
    GlSprintf,
    IssuableHeader,
  },
  props: {
    author: {
      type: Object,
      required: true,
    },
    confidential: {
      type: Boolean,
      required: true,
    },
    createdAt: {
      type: String,
      required: true,
    },
    duplicatedToIssueUrl: {
      type: String,
      required: true,
    },
    isFirstContribution: {
      type: Boolean,
      required: true,
    },
    isHidden: {
      type: Boolean,
      required: true,
    },
    isImported: {
      type: Boolean,
      required: true,
    },
    isLocked: {
      type: Boolean,
      required: true,
    },
    issuableState: {
      type: String,
      required: true,
    },
    issuableType: {
      type: String,
      required: true,
    },
    movedToIssueUrl: {
      type: String,
      required: true,
    },
    promotedToEpicUrl: {
      type: String,
      required: true,
    },
    serviceDeskReplyTo: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    closedStatusLink() {
      return this.duplicatedToIssueUrl || this.movedToIssueUrl || this.promotedToEpicUrl;
    },
    closedStatusText() {
      if (this.duplicatedToIssueUrl) {
        return s__('IssuableStatus|duplicated');
      }
      if (this.movedToIssueUrl) {
        return s__('IssuableStatus|moved');
      }
      if (this.promotedToEpicUrl) {
        return s__('IssuableStatus|promoted');
      }
      return '';
    },
    isOpen() {
      return this.issuableState === STATUS_OPEN || this.issuableState === STATUS_REOPENED;
    },
    statusIcon() {
      return this.isOpen ? 'issue-open-m' : 'issue-close';
    },
    statusText() {
      if (this.isOpen) {
        return __('Open');
      }
      if (this.closedStatusLink) {
        return s__('IssuableStatus|Closed (%{link})');
      }
      return s__('IssuableStatus|Closed');
    },
  },
};
</script>

<template>
  <issuable-header
    :author="author"
    :blocked="isLocked"
    :confidential="confidential"
    :created-at="createdAt"
    :is-first-contribution="isFirstContribution"
    :is-hidden="isHidden"
    :is-imported="isImported"
    :issuable-state="issuableState"
    :issuable-type="issuableType"
    :service-desk-reply-to="serviceDeskReplyTo"
    show-work-item-type-icon
    :status-icon="statusIcon"
    :workspace-type="$options.WORKSPACE_PROJECT"
  >
    <template #status-badge>
      <gl-sprintf v-if="closedStatusLink" :message="statusText">
        <template #link>
          <gl-link class="!gl-text-inherit gl-underline" :href="closedStatusLink">{{
            closedStatusText
          }}</gl-link>
        </template>
      </gl-sprintf>
      <template v-else>{{ statusText }}</template>
    </template>
  </issuable-header>
</template>
