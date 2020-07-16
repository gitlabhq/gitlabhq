<script>
import { GlLoadingIcon, GlTooltipDirective, GlDeprecatedButton } from '@gitlab/ui';
import CiStatus from '~/vue_shared/components/ci_icon.vue';
import { __, sprintf } from '~/locale';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    CiStatus,
    GlLoadingIcon,
    GlDeprecatedButton,
  },
  props: {
    pipeline: {
      type: Object,
      required: true,
    },
    projectId: {
      type: Number,
      required: true,
    },
    columnTitle: {
      type: String,
      required: true,
    },
  },
  computed: {
    tooltipText() {
      return `${this.downstreamTitle} #${this.pipeline.id} - ${this.pipelineStatus.label}
      ${this.sourceJobInfo}`;
    },
    buttonId() {
      return `js-linked-pipeline-${this.pipeline.id}`;
    },
    pipelineStatus() {
      return this.pipeline.details.status;
    },
    projectName() {
      return this.pipeline.project.name;
    },
    downstreamTitle() {
      return this.childPipeline ? __('child-pipeline') : this.pipeline.project.name;
    },
    parentPipeline() {
      // Refactor string match when BE returns Upstream/Downstream indicators
      return this.projectId === this.pipeline.project.id && this.columnTitle === __('Upstream');
    },
    childPipeline() {
      // Refactor string match when BE returns Upstream/Downstream indicators
      return this.projectId === this.pipeline.project.id && this.isDownstream;
    },
    label() {
      if (this.parentPipeline) {
        return __('Parent');
      } else if (this.childPipeline) {
        return __('Child');
      }
      return __('Multi-project');
    },
    isDownstream() {
      return this.columnTitle === __('Downstream');
    },
    sourceJobInfo() {
      return this.isDownstream
        ? sprintf(__('Created by %{job}'), { job: this.pipeline.source_job.name })
        : '';
    },
  },
  methods: {
    onClickLinkedPipeline() {
      this.$root.$emit('bv::hide::tooltip', this.buttonId);
      this.$emit('pipelineClicked', this.$refs.linkedPipeline);
    },
    hideTooltips() {
      this.$root.$emit('bv::hide::tooltip');
    },
    onDownstreamHovered() {
      this.$emit('downstreamHovered', this.pipeline.source_job.name);
    },
    onDownstreamHoverLeave() {
      this.$emit('downstreamHovered', '');
    },
  },
};
</script>

<template>
  <li
    ref="linkedPipeline"
    class="linked-pipeline build"
    :class="{ 'downstream-pipeline': isDownstream }"
    data-qa-selector="child_pipeline"
    @mouseover="onDownstreamHovered"
    @mouseleave="onDownstreamHoverLeave"
  >
    <gl-deprecated-button
      :id="buttonId"
      v-gl-tooltip
      :title="tooltipText"
      class="js-linked-pipeline-content linked-pipeline-content"
      data-qa-selector="linked_pipeline_button"
      :class="`js-pipeline-expand-${pipeline.id}`"
      @click="onClickLinkedPipeline"
    >
      <gl-loading-icon v-if="pipeline.isLoading" class="js-linked-pipeline-loading d-inline" />
      <ci-status
        v-else
        :status="pipelineStatus"
        css-classes="position-top-0"
        class="js-linked-pipeline-status"
      />
      <span class="str-truncated"> {{ downstreamTitle }} &#8226; #{{ pipeline.id }} </span>
      <div class="gl-pt-2">
        <span class="badge badge-primary" data-testid="downstream-pipeline-label">{{ label }}</span>
      </div>
    </gl-deprecated-button>
  </li>
</template>
