<script>
import { escape, capitalize } from 'lodash';
import { GlLoadingIcon } from '@gitlab/ui';
import StageColumnComponent from './stage_column_component.vue';
import GraphWidthMixin from '../../mixins/graph_width_mixin';
import LinkedPipelinesColumn from './linked_pipelines_column.vue';
import GraphBundleMixin from '../../mixins/graph_pipeline_bundle_mixin';

export default {
  name: 'PipelineGraph',
  components: {
    StageColumnComponent,
    GlLoadingIcon,
    LinkedPipelinesColumn,
  },
  mixins: [GraphWidthMixin, GraphBundleMixin],
  props: {
    isLoading: {
      type: Boolean,
      required: true,
    },
    pipeline: {
      type: Object,
      required: true,
    },
    isLinkedPipeline: {
      type: Boolean,
      required: false,
      default: false,
    },
    mediator: {
      type: Object,
      required: true,
    },
    type: {
      type: String,
      required: false,
      default: 'main',
    },
  },
  upstream: 'upstream',
  downstream: 'downstream',
  data() {
    return {
      downstreamMarginTop: null,
      jobName: null,
      pipelineExpanded: {
        jobName: '',
        expanded: false,
      },
    };
  },
  computed: {
    graph() {
      return this.pipeline.details?.stages;
    },
    hasTriggeredBy() {
      return (
        this.type !== this.$options.downstream &&
        this.triggeredByPipelines &&
        this.pipeline.triggered_by !== null
      );
    },
    triggeredByPipelines() {
      return this.pipeline.triggered_by;
    },
    hasTriggered() {
      return (
        this.type !== this.$options.upstream &&
        this.triggeredPipelines &&
        this.pipeline.triggered.length > 0
      );
    },
    triggeredPipelines() {
      return this.pipeline.triggered;
    },
    expandedTriggeredBy() {
      return (
        this.pipeline.triggered_by &&
        Array.isArray(this.pipeline.triggered_by) &&
        this.pipeline.triggered_by.find(el => el.isExpanded)
      );
    },
    expandedTriggered() {
      return this.pipeline.triggered && this.pipeline.triggered.find(el => el.isExpanded);
    },
    pipelineTypeUpstream() {
      return this.type !== this.$options.downstream && this.expandedTriggeredBy;
    },
    pipelineTypeDownstream() {
      return this.type !== this.$options.upstream && this.expandedTriggered;
    },
    pipelineProjectId() {
      return this.pipeline.project.id;
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
      if (this.expandedTriggered?.id !== pipeline.id) {
        this.$emit('onResetTriggered', this.pipeline, pipeline);
      }

      this.$emit('onClickTriggered', pipeline);
    },
    calculateMarginTop(downstreamNode, pixelDiff) {
      return `${downstreamNode.offsetTop - downstreamNode.offsetParent.offsetTop - pixelDiff}px`;
    },
    hasOnlyOneJob(stage) {
      return stage.groups.length === 1;
    },
    hasUpstream(index) {
      return index === 0 && this.hasTriggeredBy;
    },
    setJob(jobName) {
      this.jobName = jobName;
    },
    setPipelineExpanded(jobName, expanded) {
      if (expanded) {
        this.pipelineExpanded = {
          jobName,
          expanded,
        };
      } else {
        this.pipelineExpanded = {
          expanded,
          jobName: '',
        };
      }
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
      <div
        :style="{
          paddingLeft: `${graphLeftPadding}px`,
          paddingRight: `${graphRightPadding}px`,
        }"
      >
        <gl-loading-icon v-if="isLoading" class="m-auto" size="lg" />

        <pipeline-graph
          v-if="pipelineTypeUpstream"
          type="upstream"
          class="d-inline-block upstream-pipeline"
          :class="`js-upstream-pipeline-${expandedTriggeredBy.id}`"
          :is-loading="false"
          :pipeline="expandedTriggeredBy"
          :is-linked-pipeline="true"
          :mediator="mediator"
          @onClickTriggeredBy="clickTriggeredByPipeline"
          @refreshPipelineGraph="requestRefreshPipelineGraph"
        />

        <linked-pipelines-column
          v-if="hasTriggeredBy"
          :linked-pipelines="triggeredByPipelines"
          :column-title="__('Upstream')"
          :project-id="pipelineProjectId"
          graph-position="left"
          @linkedPipelineClick="$emit('onClickTriggeredBy', $event)"
        />

        <ul
          v-if="!isLoading"
          :class="{
            'inline js-has-linked-pipelines': hasTriggered || hasTriggeredBy,
          }"
          class="stage-column-list align-top"
        >
          <stage-column-component
            v-for="(stage, index) in graph"
            :key="stage.name"
            :class="{
              'has-upstream gl-ml-11': hasUpstream(index),
              'has-only-one-job': hasOnlyOneJob(stage),
              'gl-mr-26': shouldAddRightMargin(index),
            }"
            :title="capitalizeStageName(stage.name)"
            :groups="stage.groups"
            :stage-connector-class="stageConnectorClass(index, stage)"
            :is-first-column="isFirstColumn(index)"
            :has-triggered-by="hasTriggeredBy"
            :action="stage.status.action"
            :job-hovered="jobName"
            :pipeline-expanded="pipelineExpanded"
            @refreshPipelineGraph="refreshPipelineGraph"
          />
        </ul>

        <linked-pipelines-column
          v-if="hasTriggered"
          :linked-pipelines="triggeredPipelines"
          :column-title="__('Downstream')"
          :project-id="pipelineProjectId"
          graph-position="right"
          @linkedPipelineClick="handleClickedDownstream"
          @downstreamHovered="setJob"
          @pipelineExpandToggle="setPipelineExpanded"
        />

        <pipeline-graph
          v-if="pipelineTypeDownstream"
          type="downstream"
          class="d-inline-block"
          :class="`js-downstream-pipeline-${expandedTriggered.id}`"
          :is-loading="false"
          :pipeline="expandedTriggered"
          :is-linked-pipeline="true"
          :style="{ 'margin-top': downstreamMarginTop }"
          :mediator="mediator"
          @onClickTriggered="clickTriggeredPipeline"
          @refreshPipelineGraph="requestRefreshPipelineGraph"
        />
      </div>
    </div>
  </div>
</template>
