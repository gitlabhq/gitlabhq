<script>
import LinkedPipeline from './linked_pipeline.vue';
import { __ } from '~/locale';

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
    projectId: {
      type: Number,
      required: true,
    },
  },
  computed: {
    columnClass() {
      const positionValues = {
        right: 'prepend-left-64',
        left: 'gl-mr-7',
      };
      return `graph-position-${this.graphPosition} ${positionValues[this.graphPosition]}`;
    },
    // Refactor string match when BE returns Upstream/Downstream indicators
    isUpstream() {
      return this.columnTitle === __('Upstream');
    },
  },
  methods: {
    onPipelineClick(downstreamNode, pipeline, index) {
      this.$emit('linkedPipelineClick', pipeline, index, downstreamNode);
    },
    onDownstreamHovered(jobName) {
      this.$emit('downstreamHovered', jobName);
    },
  },
};
</script>

<template>
  <div :class="columnClass" class="stage-column linked-pipelines-column">
    <div class="stage-name linked-pipelines-column-title">{{ columnTitle }}</div>
    <div v-if="isUpstream" class="cross-project-triangle"></div>
    <ul>
      <linked-pipeline
        v-for="(pipeline, index) in linkedPipelines"
        :key="pipeline.id"
        :class="{
          active: pipeline.isExpanded,
          'left-connector': pipeline.isExpanded && graphPosition === 'left',
        }"
        :pipeline="pipeline"
        :column-title="columnTitle"
        :project-id="projectId"
        @pipelineClicked="onPipelineClick($event, pipeline, index)"
        @downstreamHovered="onDownstreamHovered"
      />
    </ul>
  </div>
</template>
