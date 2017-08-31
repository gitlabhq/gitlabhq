<script>
  import Graph from './graph.vue';

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
      Graph,
    },
    computed: {
      bootstrapClass() {
        return this.rowData.length >= 2 ? 'col-md-6' : 'col-md-12';
      },
    },
  };
</script>

<template>
  <div class="prometheus-row row">
    <graph
      v-for="(graphData, index) in rowData"
      :graph-data="graphData"
      :class-type="bootstrapClass"
      :key="index"
      :update-aspect-ratio="updateAspectRatio"
      :deployment-data="deploymentData"
    />
  </div>
</template>
