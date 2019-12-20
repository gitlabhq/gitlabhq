<script>
import _ from 'underscore';
import { GlLoadingIcon } from '@gitlab/ui';
import StageColumnComponent from './stage_column_component.vue';
import GraphMixin from '../../mixins/graph_component_mixin';
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
  mixins: [GraphMixin, GraphWidthMixin, GraphBundleMixin],
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
      triggeredTopIndex: 1,
    };
  },
  computed: {
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
        _.isArray(this.pipeline.triggered_by) &&
        this.pipeline.triggered_by.find(el => el.isExpanded)
      );
    },
    expandedTriggered() {
      return this.pipeline.triggered && this.pipeline.triggered.find(el => el.isExpanded);
    },

    /**
     * Calculates the margin top of the clicked downstream pipeline by
     * adding the height of each linked pipeline and the margin
     */
    marginTop() {
      return `${this.triggeredTopIndex * 52}px`;
    },
    pipelineTypeUpstream() {
      return this.type !== this.$options.downstream && this.expandedTriggeredBy;
    },
    pipelineTypeDownstream() {
      return this.type !== this.$options.upstream && this.expandedTriggered;
    },
  },
  methods: {
    handleClickedDownstream(pipeline, clickedIndex) {
      this.triggeredTopIndex = clickedIndex;
      this.$emit('onClickTriggered', this.pipeline, pipeline);
    },
    hasOnlyOneJob(stage) {
      return stage.groups.length === 1;
    },
    hasUpstream(index) {
      return index === 0 && this.hasTriggeredBy;
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
        <gl-loading-icon v-if="isLoading" class="m-auto" :size="3" />

        <pipeline-graph
          v-if="pipelineTypeUpstream"
          type="upstream"
          class="d-inline-block upstream-pipeline"
          :class="`js-upstream-pipeline-${expandedTriggeredBy.id}`"
          :is-loading="false"
          :pipeline="expandedTriggeredBy"
          :is-linked-pipeline="true"
          :mediator="mediator"
          @onClickTriggeredBy="
            (parentPipeline, pipeline) => clickTriggeredByPipeline(parentPipeline, pipeline)
          "
          @refreshPipelineGraph="requestRefreshPipelineGraph"
        />

        <linked-pipelines-column
          v-if="hasTriggeredBy"
          :linked-pipelines="triggeredByPipelines"
          :column-title="__('Upstream')"
          graph-position="left"
          @linkedPipelineClick="
            linkedPipeline => $emit('onClickTriggeredBy', pipeline, linkedPipeline)
          "
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
              'has-upstream prepend-left-64': hasUpstream(index),
              'has-only-one-job': hasOnlyOneJob(stage),
              'append-right-46': shouldAddRightMargin(index),
            }"
            :title="capitalizeStageName(stage.name)"
            :groups="stage.groups"
            :stage-connector-class="stageConnectorClass(index, stage)"
            :is-first-column="isFirstColumn(index)"
            :has-triggered-by="hasTriggeredBy"
            :action="stage.status.action"
            @refreshPipelineGraph="refreshPipelineGraph"
          />
        </ul>

        <linked-pipelines-column
          v-if="hasTriggered"
          :linked-pipelines="triggeredPipelines"
          :column-title="__('Downstream')"
          graph-position="right"
          @linkedPipelineClick="handleClickedDownstream"
        />

        <pipeline-graph
          v-if="pipelineTypeDownstream"
          type="downstream"
          class="d-inline-block"
          :class="`js-downstream-pipeline-${expandedTriggered.id}`"
          :is-loading="false"
          :pipeline="expandedTriggered"
          :is-linked-pipeline="true"
          :style="{ 'margin-top': marginTop }"
          :mediator="mediator"
          @onClickTriggered="
            (parentPipeline, pipeline) => clickTriggeredPipeline(parentPipeline, pipeline)
          "
          @refreshPipelineGraph="requestRefreshPipelineGraph"
        />
      </div>
    </div>
  </div>
</template>
