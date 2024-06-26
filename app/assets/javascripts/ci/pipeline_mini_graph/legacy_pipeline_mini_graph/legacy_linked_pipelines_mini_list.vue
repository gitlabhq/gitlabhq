<script>
import { GlTooltipDirective } from '@gitlab/ui';
import { sprintf, s__ } from '~/locale';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import { accessValue } from '../accessors/linked_pipelines_accessors';
/**
 * Renders the upstream/downstream portions of the pipeline mini graph.
 */
export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    CiIcon,
  },
  inject: {
    dataMethod: {
      default: 'rest',
    },
  },
  props: {
    triggeredBy: {
      type: Array,
      required: false,
      default: () => [],
    },
    triggered: {
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
    // Exactly one of these (triggeredBy and triggered) must be truthy. Never both. Never neither.
    isUpstream() {
      return Boolean(this.triggeredBy.length) && !this.triggered.length;
    },
    isDownstream() {
      return !this.triggeredBy.length && Boolean(this.triggered.length);
    },
    linkedPipelines() {
      return this.isUpstream ? this.triggeredBy : this.triggered;
    },
    totalPipelineCount() {
      return this.linkedPipelines.length;
    },
    linkedPipelinesTrimmed() {
      return this.totalPipelineCount > this.maxRenderedPipelines
        ? this.linkedPipelines.slice(0, this.maxRenderedPipelines)
        : this.linkedPipelines;
    },
    shouldRenderCounter() {
      return this.isDownstream && this.linkedPipelines.length > this.maxRenderedPipelines;
    },
    counterLabel() {
      return `+${this.linkedPipelines.length - this.maxRenderedPipelines}`;
    },
    counterTooltipText() {
      return sprintf(s__('Pipelines|%{counterLabel} more downstream pipelines'), {
        counterLabel: this.counterLabel,
      });
    },
  },
  methods: {
    pipelineTooltipText(pipeline) {
      const { label } = accessValue(pipeline, this.dataMethod, 'detailedStatus');

      return `${pipeline.project.name} - ${label}`;
      // return `${pipeline?.project?.name} - ${pipeline?.details?.status?.label}`;
    },
    pipelineStatus(pipeline) {
      // detailedStatus is graphQL, details.status is REST
      return pipeline?.detailedStatus || pipeline?.details?.status;
    },
  },
};
</script>

<template>
  <span
    v-if="linkedPipelines"
    class="linked-pipeline-mini-list gl-inline-flex gl-gap-2 gl-align-middle"
  >
    <ci-icon
      v-for="pipeline in linkedPipelinesTrimmed"
      :key="pipeline.id"
      v-gl-tooltip="{ title: pipelineTooltipText(pipeline) }"
      :status="pipelineStatus(pipeline)"
      :show-tooltip="false"
      class="linked-pipeline-mini-item gl-mb-0!"
      data-testid="linked-pipeline-mini-item"
    />

    <a
      v-if="shouldRenderCounter"
      v-gl-tooltip="{ title: counterTooltipText }"
      :title="counterTooltipText"
      :href="pipelinePath"
      class="gl-align-items-center gl-bg-gray-50 gl-inline-flex gl-font-sm gl-h-6 gl-justify-content-center gl-rounded-pill gl-text-decoration-none gl-text-gray-500 gl-w-7 linked-pipelines-counter linked-pipeline-mini-item"
      data-testid="linked-pipeline-counter"
    >
      {{ counterLabel }}
    </a>
  </span>
</template>
