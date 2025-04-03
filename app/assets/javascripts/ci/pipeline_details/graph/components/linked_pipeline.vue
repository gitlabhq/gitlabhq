<script>
import {
  GlBadge,
  GlButton,
  GlIcon,
  GlLink,
  GlLoadingIcon,
  GlPopover,
  GlSprintf,
  GlTooltipDirective,
} from '@gitlab/ui';
import { TYPENAME_CI_PIPELINE } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { BV_HIDE_TOOLTIP } from '~/lib/utils/constants';
import { __ } from '~/locale';
import CancelPipelineMutation from '~/ci/pipeline_details/graphql/mutations/cancel_pipeline.mutation.graphql';
import RetryPipelineMutation from '~/ci/pipeline_details/graphql/mutations/retry_pipeline.mutation.graphql';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import { ACTION_FAILURE, DOWNSTREAM, UPSTREAM } from '../constants';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    CiIcon,
    GlBadge,
    GlButton,
    GlIcon,
    GlLink,
    GlLoadingIcon,
    GlPopover,
    GlSprintf,
  },
  styles: {
    flatLeftBorder: ['!gl-rounded-bl-none', '!gl-rounded-tl-none'],
    flatRightBorder: ['!gl-rounded-br-none', '!gl-rounded-tr-none'],
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
  data() {
    return {
      hasActionTooltip: false,
      isActionLoading: false,
      isExpandBtnFocus: false,
    };
  },
  computed: {
    action() {
      if (this.isDownstream) {
        if (this.isCancelable) {
          return {
            icon: 'cancel',
            method: this.cancelPipeline,
            ariaLabel: __('Cancel downstream pipeline'),
          };
        }
        if (this.isRetryable) {
          return {
            icon: 'retry',
            method: this.retryPipeline,
            ariaLabel: __('Retry downstream pipeline'),
          };
        }
      }

      return {};
    },
    buttonBorderClasses() {
      return this.isUpstream
        ? ['!gl-border-r-0', ...this.$options.styles.flatRightBorder]
        : ['!gl-border-l-0', ...this.$options.styles.flatLeftBorder];
    },
    buttonShadowClass() {
      return this.isExpandBtnFocus ? '' : '!gl-shadow-none';
    },
    buttonId() {
      return `js-linked-pipeline-${this.pipeline.id}`;
    },
    cardClasses() {
      return this.isDownstream
        ? this.$options.styles.flatRightBorder
        : this.$options.styles.flatLeftBorder;
    },
    expandedIcon() {
      if (this.isUpstream) {
        return this.expanded ? 'chevron-lg-right' : 'chevron-lg-left';
      }
      return this.expanded ? 'chevron-lg-left' : 'chevron-lg-right';
    },
    expandBtnText() {
      return this.expanded ? __('Collapse jobs') : __('Expand jobs');
    },
    isChildPipeline() {
      return this.isDownstream && !this.isMultiProject;
    },
    downstreamTitle() {
      if (this.hasPipelineName) {
        return this.pipelineName;
      }
      if (!this.hasSourceJob) {
        return this.projectName;
      }

      return this.isMultiProject
        ? `${this.sourceJobName}: ${this.projectName}`
        : this.sourceJobName;
    },
    graphqlPipelineId() {
      return convertToGraphQLId(TYPENAME_CI_PIPELINE, this.pipeline.id);
    },
    hasPipelineName() {
      return Boolean(this.pipelineName);
    },
    hasUpdatePipelinePermissions() {
      return Boolean(this.pipeline?.userPermissions?.updatePipeline);
    },
    hasSourceJob() {
      return Boolean(this.pipeline?.sourceJob?.id);
    },
    isCancelable() {
      return Boolean(this.pipeline?.cancelable && this.hasUpdatePipelinePermissions);
    },
    isDownstream() {
      return this.type === DOWNSTREAM;
    },
    isRetryable() {
      return Boolean(this.pipeline?.retryable && this.hasUpdatePipelinePermissions);
    },
    isMultiProject() {
      return this.pipeline.multiproject;
    },
    isUpstream() {
      return this.type === UPSTREAM;
    },
    label() {
      if (this.parentPipeline) {
        return __('Parent');
      }
      if (this.isChildPipeline) {
        return __('Child');
      }
      return __('Multi-project');
    },
    parentPipeline() {
      return this.isUpstream && !this.isMultiProject;
    },
    pipelineIsLoading() {
      return Boolean(this.isLoading || this.pipeline.isLoading);
    },
    pipelineName() {
      return this.pipeline?.name || '';
    },
    pipelineStatus() {
      return this.pipeline.status;
    },
    projectName() {
      return this.pipeline?.project?.name || '';
    },
    popoverItems() {
      return [
        {
          condition: this.hasPipelineName,
          message: __('%{boldStart}Pipeline:%{boldEnd} %{value}'),
          value: this.pipelineName,
        },
        {
          condition: !this.isChildPipeline,
          message: __('%{boldStart}Project:%{boldEnd} %{value}'),
          value: this.projectName,
        },
        {
          condition: this.hasSourceJob,
          message: __('%{boldStart}Created by:%{boldEnd} %{value}'),
          value: this.sourceJobName,
        },
        {
          condition: true,
          message: __('%{boldStart}Status:%{boldEnd} %{value}'),
          value: this.pipeline.status.label,
        },
      ].filter((item) => item.condition);
    },
    showAction() {
      return Boolean(this.action?.method && this.action?.icon && this.action?.ariaLabel);
    },
    showCardPopover() {
      return !this.hasActionTooltip && !this.isExpandBtnFocus;
    },
    sourceJobName() {
      return this.pipeline.sourceJob?.name ?? '';
    },
  },
  methods: {
    cancelPipeline() {
      this.executePipelineAction(CancelPipelineMutation);
    },
    async executePipelineAction(mutation) {
      try {
        this.isActionLoading = true;

        await this.$apollo.mutate({
          mutation,
          variables: {
            id: this.graphqlPipelineId,
          },
        });
        this.$emit('refreshPipelineGraph');
      } catch {
        this.$emit('error', { type: ACTION_FAILURE });
      } finally {
        this.isActionLoading = false;
      }
    },
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
    retryPipeline() {
      this.executePipelineAction(RetryPipelineMutation);
    },
    setActionTooltip(flag) {
      this.hasActionTooltip = flag;
    },
    setExpandBtnActiveState(flag) {
      this.isExpandBtnFocus = flag;
    },
  },
};
</script>

<template>
  <div
    ref="linkedPipeline"
    class="linked-pipeline-container !gl-flex gl-h-full gl-w-full sm:gl-w-auto"
    :class="{
      'gl-flex-row-reverse': isUpstream,
      'gl-flex-row': !isUpstream,
    }"
    data-testid="linked-pipeline-container"
    :aria-expanded="expanded"
    @mouseover="onDownstreamHovered"
    @mouseleave="onDownstreamHoverLeave"
  >
    <gl-popover
      v-if="showCardPopover"
      :target="() => $refs.linkedPipeline"
      triggers="hover"
      placement="bottom"
    >
      <div v-for="(item, index) in popoverItems" :key="index">
        <gl-sprintf :message="item.message">
          <template #bold="{ content }">
            <strong>{{ content }}</strong>
          </template>
          <template #value>{{ item.value }}</template>
        </gl-sprintf>
      </div>
    </gl-popover>
    <div
      class="gl-border gl-flex gl-w-full gl-flex-col gl-gap-y-2 gl-rounded-lg gl-border-l-section gl-bg-section gl-p-3"
      :class="cardClasses"
    >
      <div class="gl-flex gl-w-26 gl-gap-x-3">
        <ci-icon
          v-if="!pipelineIsLoading"
          :status="pipelineStatus"
          :use-link="false"
          class="gl-self-start"
        />
        <div v-else class="gl-pr-3"><gl-loading-icon size="sm" inline /></div>
        <div class="gl-flex gl-min-w-0 gl-flex-1 gl-flex-col">
          <span class="gl-truncate" data-testid="downstream-title-content">
            {{ downstreamTitle }}
          </span>
          <div class="gl-truncate">
            <gl-link class="gl-text-sm" :href="pipeline.path" data-testid="pipelineLink"
              >#{{ pipeline.id }}</gl-link
            >
          </div>
        </div>
        <gl-button
          v-if="showAction"
          v-gl-tooltip
          :title="action.ariaLabel"
          :loading="isActionLoading"
          :icon="action.icon"
          class="gl-h-7 gl-w-7 !gl-rounded-full"
          :aria-label="action.ariaLabel"
          @click="action.method"
          @mouseover="setActionTooltip(true)"
          @mouseout="setActionTooltip(false)"
        />
      </div>
      <span
        v-if="hasSourceJob"
        class="gl-flex gl-w-26 gl-items-center gl-gap-2 gl-text-sm gl-text-subtle"
      >
        <gl-icon name="trigger-source" :size="12" class="gl-flex-shrink-0" />
        <span class="gl-truncate"> {{ sourceJobName }} </span>
      </span>
      <div class="gl-cursor-default gl-pt-2">
        <gl-badge variant="info" data-testid="downstream-pipeline-label">
          {{ label }}
        </gl-badge>
      </div>
    </div>
    <div class="gl-flex">
      <gl-button
        :id="buttonId"
        v-gl-tooltip
        :title="expandBtnText"
        class="!gl-border !gl-rounded-lg !gl-bg-section"
        :class="[`js-pipeline-expand-${pipeline.id}`, buttonBorderClasses, buttonShadowClass]"
        :icon="expandedIcon"
        :aria-label="expandBtnText"
        data-testid="expand-pipeline-button"
        @mouseover="setExpandBtnActiveState(true)"
        @mouseout="setExpandBtnActiveState(false)"
        @focus="setExpandBtnActiveState(true)"
        @blur="setExpandBtnActiveState(false)"
        @click="onClickLinkedPipeline"
      />
    </div>
  </div>
</template>
