<script>
import { GlResizeObserverDirective } from '@gitlab/ui';
import {
  generateColumnsFromLayersListMemoized,
  keepLatestDownstreamPipelines,
} from '~/ci/pipeline_details/utils/parsing_utils';
import LinksLayer from '../../../common/private/job_links_layer.vue';
import { DOWNSTREAM, MAIN, UPSTREAM, ONE_COL_WIDTH, STAGE_VIEW } from '../constants';
import { validateConfigPaths } from '../utils';
import LinkedGraphWrapper from './linked_graph_wrapper.vue';
import StageColumnComponent from './stage_column_component.vue';

export default {
  name: 'PipelineGraph',
  components: {
    LinksLayer,
    LinkedGraphWrapper,
    LinkedPipelinesColumn: () =>
      import(/* webpackChunkName: 'linked_pipelines_column' */ './linked_pipelines_column.vue'),
    StageColumnComponent,
  },
  directives: {
    GlResizeObserver: GlResizeObserverDirective,
  },
  props: {
    configPaths: {
      type: Object,
      required: true,
      validator: validateConfigPaths,
    },
    pipeline: {
      type: Object,
      required: true,
    },
    showLinks: {
      type: Boolean,
      required: true,
    },
    viewType: {
      type: String,
      required: true,
    },
    isLinkedPipeline: {
      type: Boolean,
      required: false,
      default: false,
    },
    computedPipelineInfo: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    skipRetryModal: {
      type: Boolean,
      required: false,
      default: false,
    },
    type: {
      type: String,
      required: false,
      default: MAIN,
    },
    userPermissions: {
      type: Object,
      required: true,
    },
  },
  pipelineTypeConstants: {
    DOWNSTREAM,
    UPSTREAM,
  },
  CONTAINER_REF: 'PIPELINE_LINKS_CONTAINER_REF',
  BASE_CONTAINER_ID: 'pipeline-links-container',
  data() {
    return {
      hoveredJobName: '',
      hoveredSourceJobName: '',
      highlightedJobs: [],
      measurements: {
        width: 0,
        height: 0,
      },
      pipelineExpanded: {
        jobName: '',
        expanded: false,
      },
      containerWidth: 0,
      containerScrollWidth: 0,
    };
  },
  computed: {
    containerId() {
      return `${this.$options.BASE_CONTAINER_ID}-${this.pipeline.id}`;
    },
    downstreamPipelines() {
      return this.hasDownstreamPipelines
        ? keepLatestDownstreamPipelines(this.pipeline.downstream)
        : [];
    },
    layout() {
      return this.isStageView
        ? this.pipeline.stages
        : generateColumnsFromLayersListMemoized(
            this.pipeline,
            this.computedPipelineInfo.pipelineLayers,
          );
    },
    hasDownstreamPipelines() {
      return Boolean(this.pipeline?.downstream?.length > 0);
    },
    hasUpstreamPipelines() {
      return Boolean(this.pipeline?.upstream?.length > 0);
    },
    isStageView() {
      return this.viewType === STAGE_VIEW;
    },
    linksData() {
      return this.computedPipelineInfo?.linksData ?? null;
    },
    metricsConfig() {
      return {
        path: this.configPaths.metricsPath,
        collectMetrics: true,
      };
    },
    showJobLinks() {
      return !this.isStageView && this.showLinks;
    },
    // The show downstream check prevents showing redundant linked columns
    showDownstreamPipelines() {
      return (
        this.hasDownstreamPipelines && this.type !== this.$options.pipelineTypeConstants.UPSTREAM
      );
    },
    // The show upstream check prevents showing redundant linked columns
    showUpstreamPipelines() {
      return (
        this.hasUpstreamPipelines && this.type !== this.$options.pipelineTypeConstants.DOWNSTREAM
      );
    },
    upstreamPipelines() {
      return this.hasUpstreamPipelines ? this.pipeline.upstream : [];
    },
    currentPipelinePermissions() {
      if (!this.pipeline?.id) {
        return {};
      }
      return this.userPermissions[this.pipeline?.id] || {};
    },
    hasHorizontalOverflow() {
      if (!this.containerWidth) return false;
      return this.containerScrollWidth > this.containerWidth;
    },
  },
  mounted() {
    this.$nextTick(() => {
      this.getMeasurements();
      this.updateContainerWidth();
    });
  },
  methods: {
    getMeasurements() {
      this.measurements = {
        width: this.$refs[this.containerId].scrollWidth,
        height: this.$refs[this.containerId].scrollHeight,
      };
    },
    updateContainerWidth() {
      const container = this.$refs.mainPipelineContainer;
      if (container) {
        this.containerWidth = container.clientWidth;
        this.containerScrollWidth = container.scrollWidth;
      }
    },
    syncScrollToSticky({ target }) {
      const { stickyScrollbar } = this.$refs;
      if (!stickyScrollbar) return;

      stickyScrollbar.scrollLeft = target.scrollLeft;
    },
    syncScrollFromSticky({ target }) {
      const mainContainer = this.$refs.mainPipelineContainer;
      if (!mainContainer) return;

      mainContainer.scrollLeft = target.scrollLeft;
    },
    onError(payload) {
      this.$emit('error', payload);
    },
    setJob(jobName) {
      this.hoveredJobName = jobName;
    },
    setSourceJob(jobName) {
      this.hoveredSourceJobName = jobName;
    },
    slidePipelineContainer() {
      this.$refs.mainPipelineContainer.scrollBy({
        left: ONE_COL_WIDTH,
        top: 0,
        behavior: 'smooth',
      });
    },
    togglePipelineExpanded(jobName, expanded) {
      this.pipelineExpanded = {
        expanded,
        jobName: expanded ? jobName : '',
      };
    },
    updateHighlightedJobs(jobs) {
      this.highlightedJobs = jobs;
    },
  },
};
</script>
<template>
  <div class="js-pipeline-graph">
    <div
      :ref="isLinkedPipeline ? 'linkedPipelineContainer' : 'mainPipelineContainer'"
      class="pipeline-graph gl-position-relative gl-flex gl-whitespace-nowrap gl-rounded-lg"
      :class="{
        'pipeline-graph-container gl-pipeline-min-h gl-mt-3 gl-items-start gl-overflow-auto gl-bg-subtle gl-pb-8 gl-pt-3':
          !isLinkedPipeline,
        'gl-bg-strong @sm/panel:gl-ml-5': isLinkedPipeline,
      }"
      data-testid="pipeline-container"
      @scroll="syncScrollToSticky"
    >
      <linked-graph-wrapper v-gl-resize-observer="updateContainerWidth">
        <template #upstream>
          <linked-pipelines-column
            v-if="showUpstreamPipelines"
            :config-paths="configPaths"
            :linked-pipelines="upstreamPipelines"
            :column-title="__('Upstream')"
            :show-links="showJobLinks"
            :skip-retry-modal="skipRetryModal"
            :type="$options.pipelineTypeConstants.UPSTREAM"
            :view-type="viewType"
            :user-permissions="userPermissions"
            @error="onError"
            @setSkipRetryModal="$emit('setSkipRetryModal')"
          />
        </template>
        <template #main>
          <div :id="containerId" :ref="containerId" class="pipeline-links-container">
            <links-layer
              :pipeline-data="layout"
              :pipeline-id="pipeline.id"
              :container-id="containerId"
              :container-measurements="measurements"
              :highlighted-job="hoveredJobName"
              :links-data="linksData"
              :metrics-config="metricsConfig"
              :show-links="showJobLinks"
              :view-type="viewType"
              @error="onError"
              @highlightedJobsChange="updateHighlightedJobs"
            >
              <stage-column-component
                v-for="column in layout"
                :key="column.id || column.name"
                :name="column.name"
                :groups="column.groups"
                :action="column.status.action"
                :highlighted-jobs="highlightedJobs"
                :is-stage-view="isStageView"
                :job-hovered="hoveredJobName"
                :skip-retry-modal="skipRetryModal"
                :source-job-hovered="hoveredSourceJobName"
                :pipeline-expanded="pipelineExpanded"
                :pipeline-id="pipeline.id"
                :user-permissions="currentPipelinePermissions"
                @refreshPipelineGraph="$emit('refreshPipelineGraph')"
                @setSkipRetryModal="$emit('setSkipRetryModal')"
                @jobHover="setJob"
                @updateMeasurements="getMeasurements"
              />
            </links-layer>
          </div>
        </template>
        <template #downstream>
          <linked-pipelines-column
            v-if="showDownstreamPipelines"
            class="@sm/panel:gl-ml-3"
            :config-paths="configPaths"
            :linked-pipelines="downstreamPipelines"
            :column-title="__('Downstream')"
            :skip-retry-modal="skipRetryModal"
            :show-links="showJobLinks"
            :type="$options.pipelineTypeConstants.DOWNSTREAM"
            :view-type="viewType"
            :user-permissions="userPermissions"
            data-testid="downstream-pipelines"
            @downstreamHovered="setSourceJob"
            @pipelineExpandToggle="togglePipelineExpanded"
            @refreshPipelineGraph="$emit('refreshPipelineGraph')"
            @setSkipRetryModal="$emit('setSkipRetryModal')"
            @scrollContainer="slidePipelineContainer"
            @error="onError"
          />
        </template>
      </linked-graph-wrapper>
    </div>

    <div
      v-if="!isLinkedPipeline && hasHorizontalOverflow"
      ref="stickyScrollbar"
      data-testid="sticky-scrollbar"
      class="gl-z-10 gl-border-t gl-sticky gl-bottom-0 gl-h-5 gl-overflow-x-auto gl-overflow-y-hidden gl-bg-subtle"
      @scroll="syncScrollFromSticky"
    >
      <div
        data-testid="sticky-scrollbar-inner"
        :style="{ width: `${containerScrollWidth}px` }"
        class="gl-h-1"
      ></div>
    </div>
  </div>
</template>
