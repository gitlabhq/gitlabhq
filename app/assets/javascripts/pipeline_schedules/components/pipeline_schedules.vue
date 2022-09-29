<script>
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
};
</script>

<template>
  <div>
    <pipeline-schedules-table />
  </div>
</template>
