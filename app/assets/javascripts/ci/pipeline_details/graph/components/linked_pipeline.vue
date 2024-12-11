<script>
import {
  GlBadge,
  GlButton,
  GlLink,
  GlLoadingIcon,
  GlTooltip,
  GlTooltipDirective,
} from '@gitlab/ui';
import { TYPENAME_CI_PIPELINE } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { BV_HIDE_TOOLTIP } from '~/lib/utils/constants';
import { __, sprintf } from '~/locale';
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
    GlLink,
    GlLoadingIcon,
    GlTooltip,
  },
  styles: {
    actionSizeClasses: ['gl-h-7 gl-w-7'],
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
    childPipeline() {
      return this.isDownstream && this.isSameProject;
    },
    downstreamTitle() {
      return this.childPipeline ? this.sourceJobName : this.pipeline.project.name;
    },
    graphqlPipelineId() {
      return convertToGraphQLId(TYPENAME_CI_PIPELINE, this.pipeline.id);
    },
    hasUpdatePipelinePermissions() {
      return Boolean(this.pipeline?.userPermissions?.updatePipeline);
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
    isSameProject() {
      return !this.pipeline.multiproject;
    },
    isUpstream() {
      return this.type === UPSTREAM;
    },
    label() {
      if (this.parentPipeline) {
        return __('Parent');
      }
      if (this.childPipeline) {
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
    showAction() {
      return Boolean(this.action?.method && this.action?.icon && this.action?.ariaLabel);
    },
    showCardTooltip() {
      return !this.hasActionTooltip && !this.isExpandBtnFocus;
    },
    sourceJobName() {
      return this.pipeline.sourceJob?.name ?? '';
    },
    sourceJobInfo() {
      return this.isDownstream ? sprintf(__('Created by %{job}'), { job: this.sourceJobName }) : '';
    },
    cardTooltipText() {
      return `${this.downstreamTitle} #${this.pipeline.id} - ${this.pipelineStatus.label} -
      ${this.sourceJobInfo}`;
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
    <gl-tooltip v-if="showCardTooltip" :target="() => $refs.linkedPipeline">
      {{ cardTooltipText }}
    </gl-tooltip>
    <div
      class="gl-border gl-w-full gl-rounded-lg gl-border-l-section gl-bg-section gl-p-3"
      :class="cardClasses"
    >
      <div class="gl-flex gl-gap-x-3">
        <ci-icon
          v-if="!pipelineIsLoading"
          :status="pipelineStatus"
          :use-link="false"
          class="gl-self-start"
        />
        <div v-else class="gl-pr-3"><gl-loading-icon size="sm" inline /></div>
        <div class="gl-downstream-pipeline-job-width gl-flex gl-flex-col gl-leading-normal">
          <span class="gl-truncate" data-testid="downstream-title-content">
            {{ downstreamTitle }}
          </span>
          <div class="-gl-m-2 gl-truncate gl-p-2">
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
          class="!gl-rounded-full"
          :class="$options.styles.actionSizeClasses"
          :aria-label="action.ariaLabel"
          @click="action.method"
          @mouseover="setActionTooltip(true)"
          @mouseout="setActionTooltip(false)"
        />
        <div v-else :class="$options.styles.actionSizeClasses"></div>
      </div>
      <div class="gl-ml-7 gl-pt-2">
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
