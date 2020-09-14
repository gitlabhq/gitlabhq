<script>
import { GlTooltipDirective, GlButton, GlLink, GlLoadingIcon } from '@gitlab/ui';
import CiStatus from '~/vue_shared/components/ci_icon.vue';
import { __, sprintf } from '~/locale';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    CiStatus,
    GlButton,
    GlLink,
    GlLoadingIcon,
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
  data() {
    return {
      expanded: false,
    };
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
    expandedIcon() {
      if (this.parentPipeline) {
        return this.expanded ? 'angle-right' : 'angle-left';
      }
      return this.expanded ? 'angle-left' : 'angle-right';
    },
    expandButtonPosition() {
      return this.parentPipeline ? 'gl-left-0 gl-border-r-1!' : 'gl-right-0 gl-border-l-1!';
    },
  },
  methods: {
    onClickLinkedPipeline() {
      this.$root.$emit('bv::hide::tooltip', this.buttonId);
      this.expanded = !this.expanded;
      this.$emit('pipelineClicked', this.$refs.linkedPipeline);
      this.$emit('pipelineExpandToggle', this.pipeline.source_job.name, this.expanded);
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
    v-gl-tooltip
    class="linked-pipeline build"
    :title="tooltipText"
    :class="{ 'downstream-pipeline': isDownstream }"
    data-qa-selector="child_pipeline"
    @mouseover="onDownstreamHovered"
    @mouseleave="onDownstreamHoverLeave"
  >
    <div
      class="gl-relative gl-bg-white gl-p-3 gl-border-solid gl-border-gray-100 gl-border-1"
      :class="{ 'gl-pl-9': parentPipeline }"
    >
      <div class="gl-display-flex">
        <ci-status
          v-if="!pipeline.isLoading"
          :status="pipelineStatus"
          css-classes="gl-top-0 gl-pr-2"
        />
        <div v-else class="gl-pr-2"><gl-loading-icon inline /></div>
        <div class="gl-display-flex gl-flex-direction-column gl-w-13">
          <span class="gl-text-truncate">
            {{ downstreamTitle }}
          </span>
          <div class="gl-text-truncate">
            <gl-link class="gl-text-blue-500!" :href="pipeline.path" data-testid="pipelineLink"
              >#{{ pipeline.id }}</gl-link
            >
          </div>
        </div>
      </div>
      <div class="gl-pt-2">
        <span class="badge badge-primary" data-testid="downstream-pipeline-label">{{ label }}</span>
      </div>
      <gl-button
        :id="buttonId"
        class="gl-absolute gl-top-0 gl-bottom-0 gl-shadow-none! gl-rounded-0!"
        :class="`js-pipeline-expand-${pipeline.id} ${expandButtonPosition}`"
        :icon="expandedIcon"
        data-testid="expandPipelineButton"
        data-qa-selector="expand_pipeline_button"
        @click="onClickLinkedPipeline"
      />
    </div>
  </li>
</template>
