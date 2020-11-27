<script>
import { escape, capitalize } from 'lodash';
import StageColumnComponent from './stage_column_component.vue';
import GraphBundleMixin from '../../mixins/graph_pipeline_bundle_mixin';
import { MAIN } from './constants';

export default {
  name: 'PipelineGraph',
  components: {
    StageColumnComponent,
  },
  mixins: [GraphBundleMixin],
  props: {
    isLinkedPipeline: {
      type: Boolean,
      required: false,
      default: false,
    },
    pipeline: {
      type: Object,
      required: true,
    },
    type: {
      type: String,
      required: false,
      default: MAIN,
    },
  },
  computed: {
    graph() {
      return this.pipeline.stages;
    },
  },
  methods: {
    capitalizeStageName(name) {
      const escapedName = escape(name);
      return capitalize(escapedName);
    },
    isFirstColumn(index) {
      return index === 0;
    },
    stageConnectorClass(index, stage) {
      let className;

      // If it's the first stage column and only has one job
      if (this.isFirstColumn(index) && stage.groups.length === 1) {
        className = 'no-margin';
      } else if (index > 0) {
        // If it is not the first column
        className = 'left-margin';
      }

      return className;
    },
    refreshPipelineGraph() {
      this.$emit('refreshPipelineGraph');
    },
    /**
     * CSS class is applied:
     *  - if pipeline graph contains only one stage column component
     *
     * @param {number} index
     * @returns {boolean}
     */
    shouldAddRightMargin(index) {
      return !(index === this.graph.length - 1);
    },
    handleClickedDownstream(pipeline, clickedIndex, downstreamNode) {
      /**
       * Calculates the margin top of the clicked downstream pipeline by
       * subtracting the clicked downstream pipelines offsetTop by it's parent's
       * offsetTop and then subtracting 15
       */
      this.downstreamMarginTop = this.calculateMarginTop(downstreamNode, 15);

      /**
       * If the expanded trigger is defined and the id is different than the
       * pipeline we clicked, then it means we clicked on a sibling downstream link
       * and we want to reset the pipeline store. Triggering the reset without
       * this condition would mean not allowing downstreams of downstreams to expand
       */
      if (this.expandedDownstream?.id !== pipeline.id) {
        this.$emit('onResetDownstream', this.pipeline, pipeline);
      }

      this.$emit('onClickDownstreamPipeline', pipeline);
    },
    calculateMarginTop(downstreamNode, pixelDiff) {
      return `${downstreamNode.offsetTop - downstreamNode.offsetParent.offsetTop - pixelDiff}px`;
    },
    hasOnlyOneJob(stage) {
      return stage.groups.length === 1;
    },
    hasUpstreamColumn(index) {
      return index === 0 && this.hasUpstream;
    },
  },
};
</script>
<template>
  <div class="build-content middle-block js-pipeline-graph">
    <div
      class="pipeline-visualization pipeline-graph"
      :class="{ 'pipeline-tab-content': !isLinkedPipeline }"
    >
      <div>
        <ul class="stage-column-list align-top">
          <stage-column-component
            v-for="(stage, index) in graph"
            :key="stage.name"
            :class="{
              'has-only-one-job': hasOnlyOneJob(stage),
              'gl-mr-26': shouldAddRightMargin(index),
            }"
            :title="capitalizeStageName(stage.name)"
            :groups="stage.groups"
            :stage-connector-class="stageConnectorClass(index, stage)"
            :is-first-column="isFirstColumn(index)"
            :action="stage.status.action"
            @refreshPipelineGraph="refreshPipelineGraph"
          />
        </ul>
      </div>
    </div>
  </div>
</template>
