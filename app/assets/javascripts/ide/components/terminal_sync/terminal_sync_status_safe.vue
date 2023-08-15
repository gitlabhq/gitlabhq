<script>
// eslint-disable-next-line no-restricted-imports
import { mapState } from 'vuex';
import TerminalSyncStatus from './terminal_sync_status.vue';

/**
 * It is possible that the vuex module is not registered.
 *
 * This component will gracefully handle this so the actual one can simply use `mapState(moduleName, ...)`.
 */
export default {
  components: {
    TerminalSyncStatus,
  },
  computed: {
    ...mapState(['terminalSync']),
  },
};
</script>

<template>
  <terminal-sync-status v-if="terminalSync" />
</template>
