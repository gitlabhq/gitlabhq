<script>
import linkedPipeline from './linked_pipeline.vue';

export default {
  props: {
    columnTitle: {
      type: String,
      required: true,
    },
    linkedPipelines: {
      type: Array,
      required: true,
    },
    graphPosition: {
      type: String,
      required: false,
    },
  },
  components: {
    linkedPipeline,
  },
  computed: {
    columnId() {
      return `graph-position-${this.graphPosition}`;
    },
  },
  methods: {
    flatConnectorClass(index) {
      return (index === 0 && this.graphPosition === 'right') ? 'flat-connector-before' : '';
    },
  },
};
</script>

<template>
  <div
    class="linked-pipelines-column"
    :id="columnId"
    >
    <div class="stage-name linked-pipelines-column-title"> {{ columnTitle }} </div>
    <div class="cross-project-triangle"></div>
    <ul>
      <linked-pipeline
        v-for="(pipeline, index) in linkedPipelines"
        :class="flatConnectorClass(index)"
        :key="pipeline.id"
        :pipeline-id="pipeline.id"
        :project-name="pipeline.project.name"
        :pipeline-status="pipeline.details.status"
        :pipeline-path="pipeline.path"
      />
    </ul>
  </div>
</template>
