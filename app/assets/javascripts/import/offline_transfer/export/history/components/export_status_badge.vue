<script>
import { GlBadge } from '@gitlab/ui';
import { s__ } from '~/locale';
import { STATUSES, STATUS_ICON_MAP } from '~/import_entities/constants';

export default {
  name: 'OfflineTransferExportStatusBadge',
  components: {
    GlBadge,
  },
  props: {
    status: {
      type: String,
      required: true,
    },
    hasFailures: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    // `partial` is client-side only — the API reports a finished export with
    // failures as `finished` plus `has_failures`.
    badgeStatus() {
      return this.status === STATUSES.FINISHED && this.hasFailures ? STATUSES.PARTIAL : this.status;
    },
    badge() {
      const mappedStatus = STATUS_ICON_MAP[this.badgeStatus];

      if (!mappedStatus) {
        return null;
      }
      return { ...mappedStatus, ...this.$options.statusOverrides[this.badgeStatus] };
    },
  },
  statusOverrides: {
    [STATUSES.STARTED]: { text: s__('OfflineTransferExport|Exporting…') },
  },
};
</script>

<template>
  <gl-badge v-if="badge" :icon="badge.icon" icon-optically-aligned :variant="badge.variant">
    {{ badge.text }}
  </gl-badge>
</template>
