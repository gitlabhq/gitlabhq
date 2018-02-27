<script>
  import arrowSvg from 'ee_icons/_arrow_mini_pipeline_graph.svg';
  import icon from '~/vue_shared/components/icon.vue';
  import ciStatus from '~/vue_shared/components/ci_icon.vue';
  import tooltip from '~/vue_shared/directives/tooltip';

  export default {
    directives: {
      tooltip,
    },
    components: {
      ciStatus,
      icon,
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
        arrowSvg,
        maxRenderedPipelines: 3,
      };
    },
    computed: {
      // Exactly one of these (triggeredBy and triggered) must be truthy. Never both. Never neither.
      isUpstream() {
        return !!this.triggeredBy.length && !this.triggered.length;
      },
      isDownstream() {
        return !this.triggeredBy.length && !!this.triggered.length;
      },
      linkedPipelines() {
        return this.isUpstream ? this.triggeredBy : this.triggered;
      },
      totalPipelineCount() {
        return this.linkedPipelines.length;
      },
      linkedPipelinesTrimmed() {
        return (this.totalPipelineCount > this.maxRenderedPipelines) ?
          this.linkedPipelines.slice(0, this.maxRenderedPipelines) :
          this.linkedPipelines;
      },
      shouldRenderCounter() {
        return this.isDownstream && this.linkedPipelines.length > this.maxRenderedPipelines;
      },
      counterLabel() {
        return `+${this.linkedPipelines.length - this.maxRenderedPipelines}`;
      },
      counterTooltipText() {
        return `${this.counterLabel} more downstream pipelines`;
      },
    },
    methods: {
      pipelineTooltipText(pipeline) {
        return `${pipeline.project.name} - ${pipeline.details.status.label}`;
      },
      getStatusIcon(iconName) {
        return `${iconName}_borderless`;
      },
      triggerButtonClass(group) {
        return `ci-status-icon-${group}`;
      },
    },
  };
</script>

<template>
  <span
    v-if="linkedPipelines"
    class="linked-pipeline-mini-list"
    :class="{
      'is-upstream' : isUpstream,
      'is-downstream': isDownstream
    }"
  >

    <span
      class="arrow-icon"
      v-if="isDownstream"
      v-html="arrowSvg"
      aria-hidden="true"
    >
    </span>

    <a
      v-for="pipeline in linkedPipelinesTrimmed"
      v-tooltip
      class="linked-pipeline-mini-item"
      :key="pipeline.id"
      :href="pipeline.path"
      :title="pipelineTooltipText(pipeline)"
      data-placement="top"
      data-container="body"
      :class="triggerButtonClass(pipeline.details.status.group)"
    >
      <icon
        :name="getStatusIcon(pipeline.details.status.icon)"
      />
    </a>

    <a
      v-if="shouldRenderCounter"
      v-tooltip
      class="linked-pipelines-counter linked-pipeline-mini-item"
      :title="counterTooltipText"
      :href="pipelinePath"
      data-placement="top"
      data-container="body"
    >
      {{ counterLabel }}
    </a>

    <span
      class="arrow-icon"
      v-if="isUpstream"
      v-html="arrowSvg"
      aria-hidden="true"
    >
    </span>
  </span>
</template>
