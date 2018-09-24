<script>
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
    :class="{
      'is-upstream' : isUpstream,
      'is-downstream': isDownstream
    }"
    class="linked-pipeline-mini-list"
  >

    <icon
      v-if="isDownstream"
      class="arrow-icon"
      name="long-arrow"
    />

    <a
      v-for="pipeline in linkedPipelinesTrimmed"
      :key="pipeline.id"
      v-tooltip
      :href="pipeline.path"
      :title="pipelineTooltipText(pipeline)"
      :class="triggerButtonClass(pipeline.details.status.group)"
      class="linked-pipeline-mini-item"
      data-placement="top"
      data-container="body"
    >
      <icon
        :name="getStatusIcon(pipeline.details.status.icon)"
      />
    </a>

    <a
      v-if="shouldRenderCounter"
      v-tooltip
      :title="counterTooltipText"
      :href="pipelinePath"
      class="linked-pipelines-counter linked-pipeline-mini-item"
      data-placement="top"
      data-container="body"
    >
      {{ counterLabel }}
    </a>

    <icon
      v-if="isUpstream"
      class="arrow-icon"
      name="long-arrow"
    />
  </span>
</template>
