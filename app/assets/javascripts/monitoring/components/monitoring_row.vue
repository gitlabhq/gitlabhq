<script>
  import monitoringColumn from './monitoring_column.vue';

  export default {
    props: {
      rowData: {
        type: Array,
        required: true,
      },
      updateAspectRatio: {
        type: Boolean,
        required: true,
      },
      deploymentData: {
        type: Array,
        required: true,
      },
    },
    components: {
      monitoringColumn,
    },
    computed: {
      bootstrapClass() {
        return this.rowData.length >= 2 ? 'col-md-6' : 'col-md-12';
      },
    },
  };
</script>
<template>
  <div 
    class="prometheus-row row">
    <monitoring-column
      v-for="(column, index) in rowData" 
      :column-data="column"
      :class-type="bootstrapClass"
      :key="index"
      :update-aspect-ratio="updateAspectRatio"
      :deployment-data="deploymentData"
    />
  </div>
</template>
