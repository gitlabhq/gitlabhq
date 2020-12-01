<script>
import LinkedPipeline from './linked_pipeline.vue';
import { UPSTREAM } from './constants';

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
    type: {
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
        right: 'gl-ml-11',
        left: 'gl-mr-7',
      };
      return `graph-position-${this.graphPosition} ${positionValues[this.graphPosition]}`;
    },
    graphPosition() {
      return this.isUpstream ? 'left' : 'right';
    },
    // Refactor string match when BE returns Upstream/Downstream indicators
    isUpstream() {
      return this.type === UPSTREAM;
    },
  },
  methods: {
    onPipelineClick(downstreamNode, pipeline, index) {
      this.$emit('linkedPipelineClick', pipeline, index, downstreamNode);
    },
    onDownstreamHovered(jobName) {
      this.$emit('downstreamHovered', jobName);
    },
    onPipelineExpandToggle(jobName, expanded) {
      // Highlighting only applies to downstream pipelines
      if (this.isUpstream) {
        return;
      }

      this.$emit('pipelineExpandToggle', jobName, expanded);
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
        :type="type"
        @pipelineClicked="onPipelineClick($event, pipeline, index)"
        @downstreamHovered="onDownstreamHovered"
        @pipelineExpandToggle="onPipelineExpandToggle"
      />
    </ul>
  </div>
</template>
