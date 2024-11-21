<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import { normalizeDownstreamPipelines, normalizeStages } from '../utils';
import DownstreamPipelines from '../downstream_pipelines.vue';
import PipelineStages from '../pipeline_stages.vue';
/**
 * Renders the REST instance of the pipeline mini graph.
 * Reformatting stages and downstream pipelines to match GraphQL structure.
 * We do not want to change the GraphQL files since
 * the REST version will soon be changed to GraphQL,
 * so we are keeping this logic in the legacy file.
 *
 */
export default {
  components: {
    CiIcon,
    DownstreamPipelines,
    GlIcon,
    PipelineStages,
  },
  arrowStyles: ['arrow-icon gl-inline-block gl-mx-1 gl-text-subtle !gl-align-middle'],
  directives: {
    GlTooltip: GlTooltipDirective,
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
    stages: {
      type: Array,
      required: true,
      default: () => [],
    },
    upstreamPipeline: {
      type: Object,
      required: false,
      default: () => {},
    },
  },
  emits: ['miniGraphStageClick'],
  computed: {
    formattedDownstreamPipelines() {
      return normalizeDownstreamPipelines(this.downstreamPipelines);
    },
    formattedStages() {
      return normalizeStages(this.stages);
    },
    hasDownstreamPipelines() {
      return Boolean(this.downstreamPipelines.length);
    },
    upstreamTooltipText() {
      return `${this.upstreamPipeline?.project?.name} - ${this.upstreamPipeline?.details?.status?.label}`;
    },
  },
};
</script>
<template>
  <div data-testid="pipeline-mini-graph">
    <ci-icon
      v-if="upstreamPipeline"
      v-gl-tooltip.hover
      :title="upstreamTooltipText"
      :aria-label="upstreamTooltipText"
      :status="upstreamPipeline.details.status"
      :show-tooltip="false"
      class="gl-align-middle"
      data-testid="pipeline-mini-graph-upstream"
    />
    <gl-icon
      v-if="upstreamPipeline"
      :class="$options.arrowStyles"
      name="arrow-right"
      data-testid="upstream-arrow-icon"
      variant="subtle"
    />
    <pipeline-stages
      :is-merge-train="isMergeTrain"
      :stages="formattedStages"
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
      :pipelines="formattedDownstreamPipelines"
      :pipeline-path="pipelinePath"
      data-testid="pipeline-mini-graph-downstream"
    />
  </div>
</template>
