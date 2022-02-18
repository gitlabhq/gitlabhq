<script>
import { GlBadge, GlButton, GlLink, GlLoadingIcon, GlTooltipDirective } from '@gitlab/ui';
import { BV_HIDE_TOOLTIP } from '~/lib/utils/constants';
import { __, sprintf } from '~/locale';
import CiStatus from '~/vue_shared/components/ci_icon.vue';
import { reportToSentry } from '../../utils';
import { DOWNSTREAM, UPSTREAM } from './constants';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    CiStatus,
    GlBadge,
    GlButton,
    GlLink,
    GlLoadingIcon,
  },
  props: {
    columnTitle: {
      type: String,
      required: true,
    },
    expanded: {
      type: Boolean,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
    pipeline: {
      type: Object,
      required: true,
    },
    type: {
      type: String,
      required: true,
    },
  },
  computed: {
    buttonBorderClass() {
      return this.isUpstream ? 'gl-border-r-1!' : 'gl-border-l-1!';
    },
    buttonId() {
      return `js-linked-pipeline-${this.pipeline.id}`;
    },
    cardSpacingClass() {
      return this.isDownstream ? 'gl-pr-0' : '';
    },
    expandedIcon() {
      if (this.isUpstream) {
        return this.expanded ? 'angle-right' : 'angle-left';
      }
      return this.expanded ? 'angle-left' : 'angle-right';
    },
    childPipeline() {
      return this.isDownstream && this.isSameProject;
    },
    downstreamTitle() {
      return this.childPipeline ? this.sourceJobName : this.pipeline.project.name;
    },
    flexDirection() {
      return this.isUpstream ? 'gl-flex-direction-row-reverse' : 'gl-flex-direction-row';
    },
    isDownstream() {
      return this.type === DOWNSTREAM;
    },
    isSameProject() {
      return !this.pipeline.multiproject;
    },
    isUpstream() {
      return this.type === UPSTREAM;
    },
    label() {
      if (this.parentPipeline) {
        return __('Parent');
      } else if (this.childPipeline) {
        return __('Child');
      }
      return __('Multi-project');
    },
    parentPipeline() {
      return this.isUpstream && this.isSameProject;
    },
    pipelineIsLoading() {
      return Boolean(this.isLoading || this.pipeline.isLoading);
    },
    pipelineStatus() {
      return this.pipeline.status;
    },
    projectName() {
      return this.pipeline.project.name;
    },
    sourceJobName() {
      return this.pipeline.sourceJob?.name ?? '';
    },
    sourceJobInfo() {
      return this.isDownstream ? sprintf(__('Created by %{job}'), { job: this.sourceJobName }) : '';
    },
    tooltipText() {
      return `${this.downstreamTitle} #${this.pipeline.id} - ${this.pipelineStatus.label} -
      ${this.sourceJobInfo}`;
    },
  },
  errorCaptured(err, _vm, info) {
    reportToSentry('linked_pipeline', `error: ${err}, info: ${info}`);
  },
  methods: {
    hideTooltips() {
      this.$root.$emit(BV_HIDE_TOOLTIP);
    },
    onClickLinkedPipeline() {
      this.hideTooltips();
      this.$emit('pipelineClicked', this.$refs.linkedPipeline);
      this.$emit('pipelineExpandToggle', this.sourceJobName, !this.expanded);
    },
    onDownstreamHovered() {
      this.$emit('downstreamHovered', this.sourceJobName);
    },
    onDownstreamHoverLeave() {
      this.$emit('downstreamHovered', '');
    },
  },
};
</script>

<template>
  <div
    ref="linkedPipeline"
    v-gl-tooltip
    class="gl-h-full gl-display-flex! gl-border-solid gl-border-gray-100 gl-border-1"
    :class="flexDirection"
    :title="tooltipText"
    data-qa-selector="child_pipeline"
    @mouseover="onDownstreamHovered"
    @mouseleave="onDownstreamHoverLeave"
  >
    <div class="gl-w-full gl-bg-white gl-p-3" :class="cardSpacingClass">
      <div class="gl-display-flex gl-pr-3">
        <ci-status
          v-if="!pipelineIsLoading"
          :status="pipelineStatus"
          :size="24"
          css-classes="gl-top-0 gl-pr-2"
        />
        <div v-else class="gl-pr-3"><gl-loading-icon size="sm" inline /></div>
        <div class="gl-display-flex gl-flex-direction-column gl-downstream-pipeline-job-width">
          <span class="gl-text-truncate" data-testid="downstream-title">
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
        <gl-badge size="sm" variant="info" data-testid="downstream-pipeline-label">
          {{ label }}
        </gl-badge>
      </div>
    </div>
    <div class="gl-display-flex">
      <gl-button
        :id="buttonId"
        class="gl-shadow-none! gl-rounded-0!"
        :class="`js-pipeline-expand-${pipeline.id} ${buttonBorderClass}`"
        :icon="expandedIcon"
        :aria-label="__('Expand pipeline')"
        data-testid="expand-pipeline-button"
        data-qa-selector="expand_pipeline_button"
        @click="onClickLinkedPipeline"
      />
    </div>
  </div>
</template>
