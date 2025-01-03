<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import { keepLatestDownstreamPipelines } from '~/ci/pipeline_details/utils/parsing_utils';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import DownstreamPipelines from './downstream_pipelines.vue';
import PipelineStages from './pipeline_stages.vue';
/**
 * Renders the GraphQL instance of the pipeline mini graph.
 */
export default {
  name: 'PipelineMiniGraph',
  i18n: {
    pipelineMiniGraphFetchError: __('There was a problem fetching the pipeline mini graph.'),
  },
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
    latestDownstreamPipelines() {
      return keepLatestDownstreamPipelines(this.downstreamPipelines);
    },
    hasDownstreamPipelines() {
      return Boolean(this.latestDownstreamPipelines.length);
    },
    hasUpstreamPipeline() {
      return this.upstreamPipeline?.id;
    },
    upstreamTooltipText() {
      return `${this.upstreamPipeline?.project?.name} - ${this.upstreamPipeline?.detailedStatus?.label}`;
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
      :status="upstreamPipeline.detailedStatus"
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
      :stages="pipelineStages"
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
