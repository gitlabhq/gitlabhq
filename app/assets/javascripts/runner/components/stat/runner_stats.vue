<script>
import { STATUS_ONLINE, STATUS_OFFLINE, STATUS_STALE } from '../../constants';
import RunnerStatusStat from './runner_status_stat.vue';

export default {
  components: {
    RunnerStatusStat,
    RunnerUpgradeStatusStats: () =>
      import('ee_component/runner/components/stat/runner_upgrade_status_stats.vue'),
  },
  props: {
    scope: {
      type: String,
      required: true,
    },
    variables: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  methods: {
    statusCountSkip(status) {
      // Show an empty result when we already filter by another status
      return this.variables.status && this.variables.status !== status;
    },
  },
  STATUS_LIST: [STATUS_ONLINE, STATUS_OFFLINE, STATUS_STALE],
};
</script>
<template>
  <div class="gl-display-flex gl-flex-wrap gl-py-6">
    <runner-status-stat
      v-for="status in $options.STATUS_LIST"
      :key="status"
      class="gl-px-5"
      :variables="variables"
      :scope="scope"
      :status="status"
    />

    <runner-upgrade-status-stats
      class="gl-display-contents"
      :scope="scope"
      :variables="variables"
    />
  </div>
</template>
