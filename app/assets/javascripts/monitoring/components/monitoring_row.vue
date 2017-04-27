<script>
  import MonitoringColumn from './monitoring_column.vue';

  export default {
    props: {
      rowData: {
        type: Array,
        required: true,
        default: () => [],
      },
    },
    components: {
      'monitoring-column': MonitoringColumn,
    },
    methods: {
      bootstrapClass() {
        return this.rowData.length > 3 ? 'col-md-6' : 'col-md-12';
      },
    },
  };
</script>
<template>
  <div class="prometheus-row row">
    <monitoring-column
      v-for="(column, index) in rowData" 
      :columnData="column"
      :classType="bootstrapClass()"
      :key="index" 
    />
  </div>
</template>
