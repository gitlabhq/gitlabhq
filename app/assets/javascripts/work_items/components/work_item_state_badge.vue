<script>
import { GlBadge, GlLink, GlSprintf } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { STATE_OPEN } from '../constants';

export default {
  components: {
    GlBadge,
    GlLink,
    GlSprintf,
  },
  props: {
    workItemState: {
      type: String,
      required: true,
    },
    showIcon: {
      type: Boolean,
      required: false,
      default: true,
    },
    movedToWorkItemUrl: {
      type: String,
      required: false,
      default: '',
    },
    duplicatedToWorkItemUrl: {
      type: String,
      required: false,
      default: '',
    },
    promotedToEpicUrl: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    isWorkItemOpen() {
      return this.workItemState === STATE_OPEN;
    },
    workItemStateIcon() {
      if (!this.showIcon) {
        return null;
      }

      return this.isWorkItemOpen ? 'issue-open-m' : 'issue-close';
    },
    workItemStateVariant() {
      return this.isWorkItemOpen ? 'success' : 'info';
    },
    statusText() {
      if (this.isWorkItemOpen) {
        return __('Open');
      }
      if (this.closedStatusLink) {
        return s__('IssuableStatus|Closed (%{link})');
      }
      return __('Closed');
    },
    closedStatusLink() {
      return this.duplicatedToWorkItemUrl || this.movedToWorkItemUrl || this.promotedToEpicUrl;
    },
    closedStatusText() {
      if (this.duplicatedToWorkItemUrl) {
        return s__('IssuableStatus|duplicated');
      }
      if (this.movedToWorkItemUrl) {
        return s__('IssuableStatus|moved');
      }
      if (this.promotedToEpicUrl) {
        return s__('IssuableStatus|promoted');
      }
      return '';
    },
  },
};
</script>

<template>
  <gl-badge :variant="workItemStateVariant" :icon="workItemStateIcon" class="gl-align-middle">
    <gl-sprintf v-if="closedStatusLink" :message="statusText">
      <template #link>
        <gl-link class="!gl-text-inherit gl-underline" :href="closedStatusLink">{{
          closedStatusText
        }}</gl-link>
      </template>
    </gl-sprintf>
    <template v-else>{{ statusText }}</template>
  </gl-badge>
</template>
