<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { escape, capitalize } from 'lodash';
import GraphBundleMixin from '../../mixins/graph_pipeline_bundle_mixin';
import { reportToSentry } from '../../utils';
import { UPSTREAM, DOWNSTREAM, MAIN } from './constants';
import LinkedPipelinesColumnLegacy from './linked_pipelines_column_legacy.vue';
import StageColumnComponentLegacy from './stage_column_component_legacy.vue';

export default {
  name: 'PipelineGraphLegacy',
  components: {
    GlLoadingIcon,
    LinkedPipelinesColumnLegacy,
    StageColumnComponentLegacy,
  },
  mixins: [GraphBundleMixin],
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
      default: MAIN,
    },
  },
  upstream: UPSTREAM,
  downstream: DOWNSTREAM,
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
    hasUpstream() {
      return (
        this.type !== this.$options.downstream &&
        this.upstreamPipelines &&
        this.pipeline.triggered_by !== null
      );
    },
    upstreamPipelines() {
      return this.pipeline.triggered_by;
    },
    hasDownstream() {
      return (
        this.type !== this.$options.upstream &&
        this.downstreamPipelines &&
        this.pipeline.triggered.length > 0
      );
    },
    downstreamPipelines() {
      return this.pipeline.triggered;
    },
    expandedUpstream() {
      return (
        this.pipeline.triggered_by &&
        Array.isArray(this.pipeline.triggered_by) &&
        this.pipeline.triggered_by.find((el) => el.isExpanded)
      );
    },
    expandedDownstream() {
      return this.pipeline.triggered && this.pipeline.triggered.find((el) => el.isExpanded);
    },
    pipelineTypeUpstream() {
      return this.type !== this.$options.downstream && this.expandedUpstream;
    },
    pipelineTypeDownstream() {
      return this.type !== this.$options.upstream && this.expandedDownstream;
    },
    pipelineProjectId() {
      return this.pipeline.project.id;
    },
  },
  errorCaptured(err, _vm, info) {
    reportToSentry(this.$options.name, `error: ${err}, info: ${info}`);
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
      <div class="gl-w-full">
        <div class="container-fluid container-limited">
          <gl-loading-icon v-if="isLoading" class="m-auto" size="lg" />
          <pipeline-graph-legacy
            v-if="pipelineTypeUpstream"
            :type="$options.upstream"
            class="d-inline-block upstream-pipeline"
            :class="`js-upstream-pipeline-${expandedUpstream.id}`"
            :is-loading="false"
            :pipeline="expandedUpstream"
            :is-linked-pipeline="true"
            :mediator="mediator"
            @onClickUpstreamPipeline="clickUpstreamPipeline"
            @refreshPipelineGraph="requestRefreshPipelineGraph"
          />

          <linked-pipelines-column-legacy
            v-if="hasUpstream"
            :type="$options.upstream"
            :linked-pipelines="upstreamPipelines"
            :column-title="__('Upstream')"
            :project-id="pipelineProjectId"
            @linkedPipelineClick="$emit('onClickUpstreamPipeline', $event)"
          />

          <ul
            v-if="!isLoading"
            :class="{
              'inline js-has-linked-pipelines': hasDownstream || hasUpstream,
            }"
            class="stage-column-list align-top"
          >
            <stage-column-component-legacy
              v-for="(stage, index) in graph"
              :key="stage.name"
              :class="{
                'has-upstream gl-ml-11': hasUpstreamColumn(index),
                'has-only-one-job': hasOnlyOneJob(stage),
                'gl-mr-26': shouldAddRightMargin(index),
              }"
              :title="capitalizeStageName(stage.name)"
              :groups="stage.groups"
              :stage-connector-class="stageConnectorClass(index, stage)"
              :is-first-column="isFirstColumn(index)"
              :has-upstream="hasUpstream"
              :action="stage.status.action"
              :job-hovered="jobName"
              :pipeline-expanded="pipelineExpanded"
              @refreshPipelineGraph="refreshPipelineGraph"
            />
          </ul>

          <linked-pipelines-column-legacy
            v-if="hasDownstream"
            :type="$options.downstream"
            :linked-pipelines="downstreamPipelines"
            :column-title="__('Downstream')"
            :project-id="pipelineProjectId"
            @linkedPipelineClick="handleClickedDownstream"
            @downstreamHovered="setJob"
            @pipelineExpandToggle="setPipelineExpanded"
          />

          <pipeline-graph-legacy
            v-if="pipelineTypeDownstream"
            :type="$options.downstream"
            class="d-inline-block"
            :class="`js-downstream-pipeline-${expandedDownstream.id}`"
            :is-loading="false"
            :pipeline="expandedDownstream"
            :is-linked-pipeline="true"
            :style="{ 'margin-top': downstreamMarginTop }"
            :mediator="mediator"
            @onClickDownstreamPipeline="clickDownstreamPipeline"
            @refreshPipelineGraph="requestRefreshPipelineGraph"
          />
        </div>
      </div>
    </div>
  </div>
</template>
