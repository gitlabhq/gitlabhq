<script>
import { GlBadge } from '@gitlab/ui';
import { __ } from '~/locale';

const badgeVariants = {
  mergeRequests: { opened: 'success', closed: 'danger', merged: 'info' },
  default: { opened: 'success', closed: 'info' },
};
const badgeLabels = {
  mergeRequests: { opened: __('Open'), closed: __('Closed'), merged: __('Merged') },
  default: { opened: __('Open'), closed: __('Closed') },
};
const badgeIcons = {
  mergeRequests: {
    opened: 'merge-request-open',
    closed: 'merge-request-close',
    merged: 'merge',
  },
  default: { opened: 'issue-open-m', closed: 'issue-close' },
};

const normalizeState = (state) => {
  if (state.toLowerCase() === 'open') return 'opened';
  return state.toLowerCase();
};

const normalizeSource = (source) => {
  if (source in badgeVariants) return source;
  return 'default';
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
      default: '',
    },
  },
  data() {
    const state = normalizeState(this.data);
    const source = normalizeSource(this.source);
    const badgeVariant = badgeVariants[source][state];
    const badgeLabel = badgeLabels[source][state];
    const badgeIcon = badgeIcons[source][state];

    return { badgeVariant, badgeLabel, badgeIcon };
  },
};
</script>
<template>
  <gl-badge :variant="badgeVariant" :icon="badgeIcon">{{ badgeLabel }}</gl-badge>
</template>
