<script>
import { GlBadge, GlTooltipDirective } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import { getTimeago } from '~/lib/utils/datetime_utility';
import {
  I18N_STATUS_ONLINE,
  I18N_STATUS_NEVER_CONTACTED,
  I18N_STATUS_OFFLINE,
  I18N_STATUS_STALE,
  I18N_ONLINE_TIMEAGO_TOOLTIP,
  I18N_NEVER_CONTACTED_TOOLTIP,
  I18N_OFFLINE_TIMEAGO_TOOLTIP,
  I18N_STALE_TIMEAGO_TOOLTIP,
  I18N_STALE_NEVER_CONTACTED_TOOLTIP,
  STATUS_ONLINE,
  STATUS_NEVER_CONTACTED,
  STATUS_OFFLINE,
  STATUS_STALE,
} from '../constants';

export default {
  components: {
    GlBadge,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    runner: {
      required: true,
      type: Object,
    },
  },
  computed: {
    contactedAtTimeAgo() {
      if (this.runner.contactedAt) {
        return getTimeago().format(this.runner.contactedAt);
      }
      // Prevent "just now" from being rendered, in case data is missing.
      return __('never');
    },
    badge() {
      switch (this.runner?.status) {
        case STATUS_ONLINE:
          return {
            icon: 'status-active',
            variant: 'success',
            label: I18N_STATUS_ONLINE,
            tooltip: this.timeAgoTooltip(I18N_ONLINE_TIMEAGO_TOOLTIP),
          };
        case STATUS_NEVER_CONTACTED:
          return {
            icon: 'time-out',
            variant: 'muted',
            label: I18N_STATUS_NEVER_CONTACTED,
            tooltip: I18N_NEVER_CONTACTED_TOOLTIP,
          };
        case STATUS_OFFLINE:
          return {
            icon: 'time-out',
            variant: 'muted',
            label: I18N_STATUS_OFFLINE,
            tooltip: this.timeAgoTooltip(I18N_OFFLINE_TIMEAGO_TOOLTIP),
          };
        case STATUS_STALE:
          return {
            icon: 'time-out',
            variant: 'warning',
            label: I18N_STATUS_STALE,
            // runner may have contacted (or not) and be stale: consider both cases.
            tooltip: this.runner.contactedAt
              ? this.timeAgoTooltip(I18N_STALE_TIMEAGO_TOOLTIP)
              : I18N_STALE_NEVER_CONTACTED_TOOLTIP,
          };
        default:
          return null;
      }
    },
  },
  methods: {
    timeAgoTooltip(text) {
      return sprintf(text, { timeAgo: this.contactedAtTimeAgo });
    },
  },
};
</script>
<template>
  <gl-badge
    v-if="badge"
    v-gl-tooltip="badge.tooltip"
    :variant="badge.variant"
    :icon="badge.icon"
    v-bind="$attrs"
  >
    {{ badge.label }}
  </gl-badge>
</template>
