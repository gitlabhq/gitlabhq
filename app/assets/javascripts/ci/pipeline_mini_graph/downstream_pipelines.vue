<script>
import { GlTooltipDirective } from '@gitlab/ui';
import { sprintf, s__ } from '~/locale';
import DownstreamPipelineDropdown from './downstream_pipeline_dropdown.vue';

/**
 * Renders the downstream portion of the pipeline mini graph.
 */
export default {
  name: 'DownstreamPipelines',
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    DownstreamPipelineDropdown,
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
};
</script>

<template>
  <span v-if="pipelines" class="gl-inline-flex gl-gap-2 gl-align-middle">
    <downstream-pipeline-dropdown
      v-for="pipeline in pipelinesTrimmed"
      :key="pipeline.id"
      :pipeline="pipeline"
      @jobActionExecuted="$emit('jobActionExecuted')"
    />

    <a
      v-if="shouldRenderCounter"
      v-gl-tooltip="{ title: counterTooltipText }"
      :title="counterTooltipText"
      :href="pipelinePath"
      class="gl-inline-flex gl-h-6 gl-w-7 gl-items-center gl-justify-center gl-rounded-pill gl-bg-strong gl-text-sm gl-text-subtle gl-no-underline"
      data-testid="downstream-pipeline-counter"
    >
      {{ counterLabel }}
    </a>
  </span>
</template>
