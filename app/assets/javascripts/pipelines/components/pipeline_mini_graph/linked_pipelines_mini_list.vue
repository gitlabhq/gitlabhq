<script>
import { GlTooltipDirective } from '@gitlab/ui';
import { sprintf, s__ } from '~/locale';
import CiIcon from '~/vue_shared/components/ci_icon.vue';
import { accessValue } from './accessors/linked_pipelines_accessors';
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
      return sprintf(s__('LinkedPipelines|%{counterLabel} more downstream pipelines'), {
        counterLabel: this.counterLabel,
      });
    },
  },
  methods: {
    pipelineTooltipText(pipeline) {
      const { label } = accessValue(pipeline, this.dataMethod, 'detailedStatus');

      return `${pipeline.project.name} - ${label}`;
    },
    pipelineStatus(pipeline) {
      // detailedStatus is graphQL, details.status is REST
      return pipeline?.detailedStatus || pipeline?.details?.status;
    },
    triggerButtonClass(pipeline) {
      const { group } = accessValue(pipeline, this.dataMethod, 'detailedStatus');

      return `ci-status-icon-${group}`;
    },
  },
};
</script>

<template>
  <span
    v-if="linkedPipelines"
    :class="{
      'is-upstream': isUpstream,
      'is-downstream': isDownstream,
    }"
    class="linked-pipeline-mini-list gl-display-inline gl-vertical-align-middle"
  >
    <a
      v-for="pipeline in linkedPipelinesTrimmed"
      :key="pipeline.id"
      v-gl-tooltip="{ title: pipelineTooltipText(pipeline) }"
      :href="pipeline.path"
      :class="triggerButtonClass(pipeline)"
      class="linked-pipeline-mini-item gl-display-inline-block gl-h-6 gl-mr-2 gl-my-2 gl-rounded-full gl-vertical-align-middle"
      data-testid="linked-pipeline-mini-item"
    >
      <ci-icon
        is-borderless
        is-interactive
        css-classes="gl-rounded-full"
        :size="24"
        :status="pipelineStatus(pipeline)"
        class="gl-align-items-center gl-border gl-display-inline-flex"
      />
    </a>

    <a
      v-if="shouldRenderCounter"
      v-gl-tooltip="{ title: counterTooltipText }"
      :title="counterTooltipText"
      :href="pipelinePath"
      class="gl-align-items-center gl-bg-gray-50 gl-display-inline-flex gl-font-sm gl-h-6 gl-justify-content-center gl-rounded-pill gl-text-decoration-none gl-text-gray-500 gl-w-7 linked-pipelines-counter linked-pipeline-mini-item"
      data-testid="linked-pipeline-counter"
    >
      {{ counterLabel }}
    </a>
  </span>
</template>
