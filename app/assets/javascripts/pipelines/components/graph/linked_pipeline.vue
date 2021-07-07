<script>
import { GlTooltipDirective, GlButton, GlLink, GlLoadingIcon, GlBadge } from '@gitlab/ui';
import { BV_HIDE_TOOLTIP } from '~/lib/utils/constants';
import { __, sprintf } from '~/locale';
import CiStatus from '~/vue_shared/components/ci_icon.vue';
import { reportToSentry } from '../../utils';
import { accessValue } from './accessors';
import { DOWNSTREAM, REST, UPSTREAM } from './constants';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    CiStatus,
    GlButton,
    GlLink,
    GlLoadingIcon,
    GlBadge,
  },
  inject: {
    dataMethod: {
      default: REST,
    },
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
    pipeline: {
      type: Object,
      required: true,
    },
    type: {
      type: String,
      required: true,
    },
    /*
      The next two props will be removed or required
      once the graph transition is done.
      See: https://gitlab.com/gitlab-org/gitlab/-/issues/291043
    */
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    projectId: {
      type: Number,
      required: false,
      default: -1,
    },
  },
  computed: {
    tooltipText() {
      return `${this.downstreamTitle} #${this.pipeline.id} - ${this.pipelineStatus.label} -
      ${this.sourceJobInfo}`;
    },
    buttonId() {
      return `js-linked-pipeline-${this.pipeline.id}`;
    },
    pipelineStatus() {
      return accessValue(this.dataMethod, 'pipelineStatus', this.pipeline);
    },
    projectName() {
      return this.pipeline.project.name;
    },
    downstreamTitle() {
      return this.childPipeline ? this.sourceJobName : this.pipeline.project.name;
    },
    parentPipeline() {
      return this.isUpstream && this.isSameProject;
    },
    childPipeline() {
      return this.isDownstream && this.isSameProject;
    },
    label() {
      if (this.parentPipeline) {
        return __('Parent');
      } else if (this.childPipeline) {
        return __('Child');
      }
      return __('Multi-project');
    },
    pipelineIsLoading() {
      return Boolean(this.isLoading || this.pipeline.isLoading);
    },
    isDownstream() {
      return this.type === DOWNSTREAM;
    },
    isUpstream() {
      return this.type === UPSTREAM;
    },
    isSameProject() {
      return this.projectId > -1
        ? this.projectId === this.pipeline.project.id
        : !this.pipeline.multiproject;
    },
    sourceJobName() {
      return accessValue(this.dataMethod, 'sourceJob', this.pipeline);
    },
    sourceJobInfo() {
      return this.isDownstream ? sprintf(__('Created by %{job}'), { job: this.sourceJobName }) : '';
    },
    expandedIcon() {
      if (this.isUpstream) {
        return this.expanded ? 'angle-right' : 'angle-left';
      }
      return this.expanded ? 'angle-left' : 'angle-right';
    },
    expandButtonPosition() {
      return this.isUpstream ? 'gl-left-0 gl-border-r-1!' : 'gl-right-0 gl-border-l-1!';
    },
  },
  errorCaptured(err, _vm, info) {
    reportToSentry('linked_pipeline', `error: ${err}, info: ${info}`);
  },
  methods: {
    onClickLinkedPipeline() {
      this.hideTooltips();
      this.$emit('pipelineClicked', this.$refs.linkedPipeline);
      this.$emit('pipelineExpandToggle', this.sourceJobName, !this.expanded);
    },
    hideTooltips() {
      this.$root.$emit(BV_HIDE_TOOLTIP);
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
    class="linked-pipeline build gl-pipeline-job-width"
    :title="tooltipText"
    :class="{ 'downstream-pipeline': isDownstream }"
    data-qa-selector="child_pipeline"
    @mouseover="onDownstreamHovered"
    @mouseleave="onDownstreamHoverLeave"
  >
    <div
      class="gl-relative gl-bg-white gl-p-3 gl-border-solid gl-border-gray-100 gl-border-1"
      :class="{ 'gl-pl-9': isUpstream }"
    >
      <div class="gl-display-flex">
        <ci-status
          v-if="!pipelineIsLoading"
          :status="pipelineStatus"
          :size="24"
          css-classes="gl-top-0 gl-pr-2"
        />
        <div v-else class="gl-pr-2"><gl-loading-icon size="sm" inline /></div>
        <div class="gl-display-flex gl-flex-direction-column gl-w-13">
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
      <gl-button
        :id="buttonId"
        class="gl-absolute gl-top-0 gl-bottom-0 gl-shadow-none! gl-rounded-0!"
        :class="`js-pipeline-expand-${pipeline.id} ${expandButtonPosition}`"
        :icon="expandedIcon"
        :aria-label="__('Expand pipeline')"
        data-testid="expand-pipeline-button"
        data-qa-selector="expand_pipeline_button"
        @click="onClickLinkedPipeline"
      />
    </div>
  </div>
</template>
