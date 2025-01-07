<script>
import { GlBadge } from '@gitlab/ui';
import { __ } from '~/locale';

const badgeVariants = {
  issues: { opened: 'success', closed: 'info' },
  mergeRequests: { opened: 'success', closed: 'danger', merged: 'info' },
};
const badgeLabels = {
  issues: { opened: __('Open'), closed: __('Closed') },
  mergeRequests: { opened: __('Open'), closed: __('Closed'), merged: __('Merged') },
};
const badgeIcons = {
  issues: { opened: 'issue-open-m', closed: 'issue-close' },
  mergeRequests: {
    opened: 'merge-request-open',
    closed: 'merge-request-close',
    merged: 'merge',
  },
};

export default {
  name: 'StatePresenter',
  components: {
    GlBadge,
  },
  props: {
    data: {
      required: true,
      type: String,
    },
    source: {
      required: false,
      type: String,
      default: 'issues',
    },
  },
  computed: {
    badgeVariant() {
      return badgeVariants[this.source][this.data];
    },
    badgeLabel() {
      return badgeLabels[this.source][this.data];
    },
    badgeIcon() {
      return badgeIcons[this.source][this.data];
    },
  },
};
</script>
<template>
  <gl-badge :variant="badgeVariant" :icon="badgeIcon">{{ badgeLabel }}</gl-badge>
</template>
