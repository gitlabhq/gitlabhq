<script>
import runnerJobCountQuery from '../graphql/list/runner_job_count.query.graphql';
import { formatJobCount } from '../utils';

export default {
  name: 'RunnerJobCount',
  props: {
    runner: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      jobCount: '-',
    };
  },
  apollo: {
    jobCount: {
      query: runnerJobCountQuery,
      variables() {
        return { id: this.runner.id };
      },
      context: {
        batchKey: 'RunnerJobCount',
      },
      update(data) {
        return formatJobCount(data?.runner?.jobCount);
      },
    },
  },
};
</script>
<template>
  <span>{{ jobCount }}</span>
</template>
