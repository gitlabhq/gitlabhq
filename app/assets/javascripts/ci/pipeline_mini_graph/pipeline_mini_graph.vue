<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { keepLatestDownstreamPipelines } from '~/ci/pipeline_details/utils/parsing_utils';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import { normalizeDownstreamPipelines, normalizeStages } from './utils/data_utils';
import DownstreamPipelines from './downstream_pipelines.vue';
import PipelineStages from './pipeline_stages.vue';
/**
 * Renders the pipeline mini graph.
 * All REST data passed in is formatted to GraphQL.
 */
export default {
  name: 'PipelineMiniGraph',
  arrowStyles: ['arrow-icon gl-inline-block gl-mx-1 gl-text-subtle !gl-align-middle'],
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    CiIcon,
    DownstreamPipelines,
    GlIcon,
    PipelineStages,
  },
  props: {
    downstreamPipelines: {
      type: Array,
      required: false,
      default: () => [],
    },
    isMergeTrain: {
      type: Boolean,
      required: false,
      default: false,
    },
    pipelinePath: {
      type: String,
      required: false,
      default: '',
    },
    pipelineStages: {
      type: Array,
      required: true,
    },
    upstreamPipeline: {
      type: Object,
      required: false,
      default: () => {},
    },
  },
  emits: ['jobActionExecuted', 'miniGraphStageClick'],
  computed: {
    formattedDownstreamPipelines() {
      return normalizeDownstreamPipelines(this.downstreamPipelines);
    },
    formattedStages() {
      return normalizeStages(this.pipelineStages);
    },
    hasDownstreamPipelines() {
      return Boolean(this.latestDownstreamPipelines.length);
    },
    hasUpstreamPipeline() {
      return this.upstreamPipeline?.id;
    },
    latestDownstreamPipelines() {
      return keepLatestDownstreamPipelines(this.formattedDownstreamPipelines);
    },
    upstreamPipelineStatus() {
      return this.upstreamPipeline?.detailedStatus || this.upstreamPipeline?.details?.status;
    },
    upstreamTooltipText() {
      return `${this.upstreamPipeline?.project?.name} - ${this.upstreamPipelineStatus?.label}`;
    },
  },
};
</script>

<template>
  <div data-testid="pipeline-mini-graph">
    <ci-icon
      v-if="hasUpstreamPipeline"
      v-gl-tooltip.hover
      :title="upstreamTooltipText"
      :aria-label="upstreamTooltipText"
      :status="upstreamPipelineStatus"
      :show-tooltip="false"
      class="gl-align-middle"
      data-testid="pipeline-mini-graph-upstream"
    />
    <gl-icon
      v-if="hasUpstreamPipeline"
      :class="$options.arrowStyles"
      name="arrow-right"
      data-testid="upstream-arrow-icon"
      variant="subtle"
    />
    <pipeline-stages
      :is-merge-train="isMergeTrain"
      :stages="formattedStages"
      @jobActionExecuted="$emit('jobActionExecuted')"
      @miniGraphStageClick="$emit('miniGraphStageClick')"
    />
    <gl-icon
      v-if="hasDownstreamPipelines"
      :class="$options.arrowStyles"
      name="arrow-right"
      data-testid="downstream-arrow-icon"
      variant="subtle"
    />
    <downstream-pipelines
      v-if="hasDownstreamPipelines"
      :pipelines="latestDownstreamPipelines"
      :pipeline-path="pipelinePath"
      data-testid="pipeline-mini-graph-downstream"
    />
  </div>
</template>
