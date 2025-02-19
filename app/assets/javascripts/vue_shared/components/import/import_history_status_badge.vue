<script>
import { GlBadge } from '@gitlab/ui';
import { IMPORT_HISTORY_TABLE_STATUS_DATA } from './constants';

/**
 * Badge formatter for showing import status. Creates a badge with predefined copy, icon and color based on the status name.
 */
export default {
  name: 'ImportHistoryStatusBadge',
  components: {
    GlBadge,
  },
  props: {
    /**
     * The name of the status, accepts one of the following:
     *
     * - `unstarted`: Not started
     * - `inProgress`: In progress
     * - `complete`: Complete
     * - `failed`: Failed
     * - `timeout`: Timeout
     */
    status: {
      type: String,
      required: true,
    },
  },
  computed: {
    statusData() {
      return IMPORT_HISTORY_TABLE_STATUS_DATA[this.status];
    },
  },
};
</script>
<template>
  <gl-badge v-bind="statusData" icon-optically-aligned>{{ statusData.label }}</gl-badge>
</template>
