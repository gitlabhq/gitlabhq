<script>
import LinkedPipeline from './linked_pipeline.vue';

export default {
  components: {
    LinkedPipeline,
  },
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
      required: true,
    },
  },
  computed: {
    columnClass() {
      const positionValues = {
        right: 'prepend-left-64',
        left: 'append-right-32',
      };
      return `graph-position-${this.graphPosition} ${positionValues[this.graphPosition]}`;
    },
  },
};
</script>

<template>
  <div :class="columnClass" class="stage-column linked-pipelines-column">
    <div class="stage-name linked-pipelines-column-title">{{ columnTitle }}</div>
    <div class="cross-project-triangle"></div>
    <ul>
      <linked-pipeline
        v-for="(pipeline, index) in linkedPipelines"
        :key="pipeline.id"
        :class="{
          'flat-connector-before': index === 0 && graphPosition === 'right',
          active: pipeline.isExpanded,
          'left-connector': pipeline.isExpanded && graphPosition === 'left',
        }"
        :pipeline="pipeline"
        @pipelineClicked="$emit('linkedPipelineClick', pipeline, index)"
      />
    </ul>
  </div>
</template>
