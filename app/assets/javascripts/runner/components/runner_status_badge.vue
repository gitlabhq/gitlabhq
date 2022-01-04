<script>
import { GlBadge, GlTooltipDirective } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import { getTimeago } from '~/lib/utils/datetime_utility';
import {
  I18N_ONLINE_RUNNER_TIMEAGO_DESCRIPTION,
  I18N_NEVER_CONTACTED_RUNNER_DESCRIPTION,
  I18N_OFFLINE_RUNNER_TIMEAGO_DESCRIPTION,
  I18N_STALE_RUNNER_DESCRIPTION,
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
      return __('n/a');
    },
    badge() {
      switch (this.runner?.status) {
        case STATUS_ONLINE:
          return {
            variant: 'success',
            label: s__('Runners|online'),
            tooltip: sprintf(I18N_ONLINE_RUNNER_TIMEAGO_DESCRIPTION, {
              timeAgo: this.contactedAtTimeAgo,
            }),
          };
        case STATUS_NEVER_CONTACTED:
          return {
            variant: 'muted',
            label: s__('Runners|never contacted'),
            tooltip: I18N_NEVER_CONTACTED_RUNNER_DESCRIPTION,
          };
        case STATUS_OFFLINE:
          return {
            variant: 'muted',
            label: s__('Runners|offline'),
            tooltip: sprintf(I18N_OFFLINE_RUNNER_TIMEAGO_DESCRIPTION, {
              timeAgo: this.contactedAtTimeAgo,
            }),
          };
        case STATUS_STALE:
          return {
            variant: 'warning',
            label: s__('Runners|stale'),
            tooltip: I18N_STALE_RUNNER_DESCRIPTION,
          };
        default:
          return null;
      }
    },
  },
};
</script>
<template>
  <gl-badge v-if="badge" v-gl-tooltip="badge.tooltip" :variant="badge.variant" v-bind="$attrs">
    {{ badge.label }}
  </gl-badge>
</template>
