<script>
import { STATUS_ONLINE, STATUS_OFFLINE, STATUS_STALE } from '../../constants';
import RunnerStatusStat from './runner_status_stat.vue';

export default {
  components: {
    RunnerStatusStat,
  },
  props: {
    onlineRunnersCount: {
      type: Number,
      required: false,
      default: null,
    },
    offlineRunnersCount: {
      type: Number,
      required: false,
      default: null,
    },
    staleRunnersCount: {
      type: Number,
      required: false,
      default: null,
    },
  },
  STATUS_ONLINE,
  STATUS_OFFLINE,
  STATUS_STALE,
};
</script>
<template>
  <div class="gl-display-flex gl-py-6">
    <runner-status-stat
      class="gl-px-5"
      :status="$options.STATUS_ONLINE"
      :value="onlineRunnersCount"
    />
    <runner-status-stat
      class="gl-px-5"
      :status="$options.STATUS_OFFLINE"
      :value="offlineRunnersCount"
    />
    <runner-status-stat
      class="gl-px-5"
      :status="$options.STATUS_STALE"
      :value="staleRunnersCount"
    />
  </div>
</template>
