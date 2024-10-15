<script>
import { GlBadge, GlTooltipDirective } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import { getTimeago, newDate } from '~/lib/utils/datetime_utility';
import { duration } from '~/lib/utils/datetime/timeago_utility';
import {
  I18N_STATUS_ONLINE,
  I18N_STATUS_NEVER_CONTACTED,
  I18N_STATUS_OFFLINE,
  I18N_STATUS_STALE,
  I18N_ONLINE_TOOLTIP,
  I18N_NEVER_CONTACTED_TOOLTIP,
  I18N_NEVER_CONTACTED_STALE_TOOLTIP,
  I18N_DISCONNECTED_TOOLTIP,
  STATUS_ONLINE,
  STATUS_NEVER_CONTACTED,
  STATUS_OFFLINE,
  STATUS_STALE,
  ONLINE_CONTACT_TIMEOUT_SECS,
  STALE_TIMEOUT_SECS,
} from '../constants';

export default {
  name: 'RunnerStatusBadge',
  components: {
    GlBadge,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: {
    onlineContactTimeoutSecs: {
      // Real value must be provided from ::Ci::Runner::ONLINE_CONTACT_TIMEOUT
      default: ONLINE_CONTACT_TIMEOUT_SECS,
    },
    staleTimeoutSecs: {
      // Real value must be provided from ::Ci::Runner::STALE_TIMEOUT
      default: STALE_TIMEOUT_SECS,
    },
  },
  props: {
    contactedAt: {
      type: String,
      required: false,
      default: null,
    },
    status: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    onlineContactTimeoutDuration() {
      return duration(this.onlineContactTimeoutSecs * 1000);
    },
    staleTimeoutDuration() {
      return duration(this.staleTimeoutSecs * 1000);
    },
    contactedAtTimeAgo() {
      if (this.contactedAt) {
        return getTimeago().format(newDate(this.contactedAt));
      }
      // Prevent "just now" from being rendered, in case data is missing.
      return __('never');
    },
    badge() {
      switch (this.status) {
        case STATUS_ONLINE:
          return {
            icon: 'status-active',
            variant: 'success',
            label: I18N_STATUS_ONLINE,
            tooltip: sprintf(I18N_ONLINE_TOOLTIP, {
              timeAgo: this.contactedAtTimeAgo,
            }),
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
            tooltip: sprintf(I18N_DISCONNECTED_TOOLTIP, {
              elapsedTime: this.onlineContactTimeoutDuration,
              timeAgo: this.contactedAtTimeAgo,
            }),
          };
        case STATUS_STALE:
          return {
            icon: 'time-out',
            variant: 'warning',
            label: I18N_STATUS_STALE,
            // runner may have contacted (or not) and be stale: consider both cases.
            tooltip: this.contactedAt
              ? sprintf(I18N_DISCONNECTED_TOOLTIP, {
                  elapsedTime: this.staleTimeoutDuration,
                  timeAgo: this.contactedAtTimeAgo,
                })
              : sprintf(I18N_NEVER_CONTACTED_STALE_TOOLTIP, {
                  elapsedTime: this.staleTimeoutDuration,
                }),
          };
        default:
          return null;
      }
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
    <span class="gl-truncate">
      {{ badge.label }}
    </span>
  </gl-badge>
</template>
