<script>
import { GlTooltipDirective } from '@gitlab/ui';
import { sprintf, s__ } from '~/locale';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
/**
 * Renders the downstream portion of the pipeline mini graph.
 */
export default {
  name: 'DownstreamPipelines',
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    CiIcon,
  },
  props: {
    pipelines: {
      type: Array,
      required: false,
      default: () => [],
    },
    pipelinePath: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      maxRenderedPipelines: 3,
    };
  },
  computed: {
    totalPipelineCount() {
      return this.pipelines.length;
    },
    pipelinesTrimmed() {
      return this.totalPipelineCount > this.maxRenderedPipelines
        ? this.pipelines.slice(0, this.maxRenderedPipelines)
        : this.pipelines;
    },
    shouldRenderCounter() {
      return this.pipelines.length > this.maxRenderedPipelines;
    },
    counterLabel() {
      return `+${this.pipelines.length - this.maxRenderedPipelines}`;
    },
    counterTooltipText() {
      return sprintf(s__('Pipelines|%{counterLabel} more downstream pipelines'), {
        counterLabel: this.counterLabel,
      });
    },
  },
  methods: {
    pipelineTooltipText(pipeline) {
      return `${pipeline?.project?.name} - ${pipeline?.detailedStatus?.label}`;
    },
  },
};
</script>

<template>
  <span v-if="pipelines" class="gl-inline-flex gl-gap-2 gl-align-middle">
    <ci-icon
      v-for="pipeline in pipelinesTrimmed"
      :key="pipeline.id"
      v-gl-tooltip.hover
      :title="pipelineTooltipText(pipeline)"
      :status="pipeline.detailedStatus"
      :show-tooltip="false"
      data-testid="downstream-pipelines"
    />

    <a
      v-if="shouldRenderCounter"
      v-gl-tooltip="{ title: counterTooltipText }"
      :title="counterTooltipText"
      :href="pipelinePath"
      class="gl-align-items-center gl-bg-gray-50 gl-inline-flex gl-font-sm gl-h-6 gl-justify-content-center gl-rounded-pill gl-text-decoration-none gl-text-gray-500 gl-w-7"
      data-testid="downstream-pipeline-counter"
    >
      {{ counterLabel }}
    </a>
  </span>
</template>
