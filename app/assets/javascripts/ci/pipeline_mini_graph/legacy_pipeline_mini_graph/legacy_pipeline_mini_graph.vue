<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_CI_PIPELINE } from '~/graphql_shared/constants';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import DownstreamPipelines from '../downstream_pipelines.vue';
import LegacyPipelineStages from './legacy_pipeline_stages.vue';
/**
 * Renders the REST instance of the pipeline mini graph.
 */
export default {
  components: {
    CiIcon,
    DownstreamPipelines,
    GlIcon,
    LegacyPipelineStages,
  },
  arrowStyles: ['arrow-icon gl-inline-block gl-mx-1 gl-text-gray-500 !gl-align-middle'],
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
    updateDropdown: {
      type: Boolean,
      required: false,
      default: false,
    },
    upstreamPipeline: {
      type: Object,
      required: false,
      default: () => {},
    },
  },
  computed: {
    formattedDownstreamPipelines() {
      /** Reformatting to match GraphQL structure.
       * We do not want to change the GraphQL files since
       * the REST version will soon be changed to GraphQL,
       * so we are keeping this logic in the legacy file.
       */
      return this.downstreamPipelines.map((p) => {
        return {
          detailedStatus: p.details.status,
          id: convertToGraphQLId(TYPENAME_CI_PIPELINE, p.id),
          path: p.path,
          project: {
            fullPath: p.project.full_path,
            name: p.project.name,
          },
        };
      });
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
    />
    <legacy-pipeline-stages
      :is-merge-train="isMergeTrain"
      :stages="stages"
      :update-dropdown="updateDropdown"
      @miniGraphStageClick="$emit('miniGraphStageClick')"
    />
    <gl-icon
      v-if="hasDownstreamPipelines"
      :class="$options.arrowStyles"
      name="arrow-right"
      data-testid="downstream-arrow-icon"
    />
    <downstream-pipelines
      v-if="hasDownstreamPipelines"
      :pipelines="formattedDownstreamPipelines"
      :pipeline-path="pipelinePath"
      data-testid="pipeline-mini-graph-downstream"
    />
  </div>
</template>
