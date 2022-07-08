<script>
import { STATUS_ONLINE, STATUS_OFFLINE, STATUS_STALE } from '../../constants';
import RunnerCount from './runner_count.vue';
import RunnerStatusStat from './runner_status_stat.vue';

export default {
  components: {
    RunnerCount,
    RunnerStatusStat,
  },
  props: {
    scope: {
      type: String,
      required: true,
    },
    variables: {
      type: Object,
      required: false,
      default: () => {},
    },
  },
  methods: {
    countVariables(vars) {
      return { ...this.variables, ...vars };
    },
    statusCountSkip(status) {
      // Show an empty result when we already filter by another status
      return this.variables.status && this.variables.status !== status;
    },
  },
  STATUS_LIST: [STATUS_ONLINE, STATUS_OFFLINE, STATUS_STALE],
};
</script>
<template>
  <div class="gl-display-flex gl-py-6">
    <runner-count
      v-for="status in $options.STATUS_LIST"
      #default="{ count }"
      :key="status"
      :scope="scope"
      :variables="countVariables({ status })"
      :skip="statusCountSkip(status)"
    >
      <runner-status-stat class="gl-px-5" :status="status" :value="count" />
    </runner-count>
  </div>
</template>
