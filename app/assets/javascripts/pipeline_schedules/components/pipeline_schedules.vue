<script>
import getPipelineSchedulesQuery from '../graphql/queries/get_pipeline_schedules.query.graphql';
import PipelineSchedulesTable from './table/pipeline_schedules_table.vue';

export default {
  components: {
    PipelineSchedulesTable,
  },
  inject: {
    fullPath: {
      default: '',
    },
  },
  apollo: {
    schedules: {
      query: getPipelineSchedulesQuery,
      variables() {
        return {
          projectPath: this.fullPath,
        };
      },
      update({ project }) {
        return project?.pipelineSchedules?.nodes || [];
      },
    },
  },
  data() {
    return {
      schedules: [],
    };
  },
};
</script>

<template>
  <div>
    <!-- Tabs will be addressed in #371989 -->

    <pipeline-schedules-table :schedules="schedules" />
  </div>
</template>
