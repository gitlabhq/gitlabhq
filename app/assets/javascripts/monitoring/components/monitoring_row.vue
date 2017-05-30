<script>
  import MonitoringColumn from './monitoring_column.vue';

  export default {
    props: {
      rowData: {
        type: Array,
        required: true,
        default: () => [],
      },
      updateAspectRatio: {
        type: Boolean,
        required: true,
        default: false,
      },
    },
    components: {
      'monitoring-column': MonitoringColumn,
    },
    methods: {
      bootstrapClass() {
        return this.rowData.length >= 2 ? 'col-md-6' : 'col-md-12';
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
      :updateAspectRatio="updateAspectRatio"
    />
  </div>
</template>
