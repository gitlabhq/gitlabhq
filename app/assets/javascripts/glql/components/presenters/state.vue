<script>
import { GlBadge } from '@gitlab/ui';
import { __ } from '~/locale';

const badgeVariants = {
  MergeRequest: { opened: 'success', closed: 'danger', merged: 'info' },
  default: { opened: 'success', closed: 'info' },
};
const badgeLabels = {
  MergeRequest: { opened: __('Open'), closed: __('Closed'), merged: __('Merged') },
  default: { opened: __('Open'), closed: __('Closed') },
};
const badgeIcons = {
  MergeRequest: {
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
    item: {
      required: true,
      type: Object,
    },
  },
  data() {
    const state = normalizeState(this.data);
    // eslint-disable-next-line no-underscore-dangle
    const source = normalizeSource(this.item?.__typename);
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
