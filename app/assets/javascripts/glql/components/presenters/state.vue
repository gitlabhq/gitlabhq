<script>
import { GlBadge } from '@gitlab/ui';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import { __ } from '~/locale';

const badgeVariants = {
  MergeRequest: { opened: 'success', closed: 'danger', merged: 'info' },
  default: { opened: 'success', closed: 'info' },
};
const badgeLabels = {
  MergeRequest: {
    opened: __('Open'),
    closed: __('Closed'),
    merged: __('Merged'),
    locked: __('Locked'),
  },
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

// Typenames whose state values follow another source's shape, e.g. the MR
// analytics dimension emits issuable-style states (opened/closed/merged).
const sourceAliases = {
  MergeRequestsAggregationResponseDimensions: 'MergeRequest',
};

const normalizeSource = (source) => {
  const aliased = sourceAliases[source] ?? source;
  if (aliased in badgeVariants) return aliased;
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
    // Fall back to a neutral badge with the normalized state for unmapped
    // states, instead of rendering an empty badge.
    const badgeVariant = badgeVariants[source][state] ?? 'neutral';
    const badgeLabel = badgeLabels[source][state] ?? capitalizeFirstCharacter(state);
    const badgeIcon = badgeIcons[source][state] ?? null;

    return { badgeVariant, badgeLabel, badgeIcon };
  },
};
</script>
<template>
  <gl-badge :variant="badgeVariant" :icon="badgeIcon">{{ badgeLabel }}</gl-badge>
</template>
