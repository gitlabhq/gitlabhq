<script>
import { GlLink, GlPopover, GlSprintf, GlTooltipDirective, GlBadge } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { SCHEDULE_ORIGIN, API_ORIGIN, TRIGGER_ORIGIN, AGENT_SESSION_ORIGIN } from '../constants';

export default {
  components: {
    GlBadge,
    GlLink,
    GlPopover,
    GlSprintf,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: {
    pipelineSchedulesPath: {
      default: '',
    },
  },
  props: {
    pipeline: {
      type: Object,
      required: true,
    },
  },
  computed: {
    isScheduled() {
      return this.pipeline.source === SCHEDULE_ORIGIN;
    },
    isTriggered() {
      return this.pipeline.source === TRIGGER_ORIGIN;
    },
    isForked() {
      return this.pipeline?.project?.forked;
    },
    showMergedResultsBadge() {
      // A merge train pipeline is technically also a merged results pipeline,
      // but we want the badges to be mutually exclusive.
      const isMergedResult =
        this.pipeline?.flags?.merged_result_pipeline ||
        this.pipeline?.mergeRequestEventType === 'MERGED_RESULT';

      return isMergedResult && !this.isMergeTrainPipeline;
    },
    showBranchBadge() {
      return this.pipeline?.flags?.type === 'branch' || this.pipeline?.type === 'branch';
    },
    showTagBadge() {
      return this.pipeline?.flags?.type === 'tag' || this.pipeline?.type === 'tag';
    },
    autoDevopsTagId() {
      return `pipeline-url-autodevops-${this.pipeline.id}`;
    },
    autoDevopsHelpPath() {
      return helpPagePath('topics/autodevops/_index.md');
    },
    isApi() {
      return this.pipeline.source === API_ORIGIN;
    },
    hasLatestFlag() {
      return this.pipeline?.flags?.latest || this.pipeline?.latest;
    },
    isMergeTrainPipeline() {
      return (
        this.pipeline?.flags?.merge_train_pipeline ||
        this.pipeline?.mergeRequestEventType === 'MERGE_TRAIN'
      );
    },
    isDetached() {
      return (
        this.pipeline?.flags?.detached_merge_request_pipeline ||
        this.pipeline?.mergeRequestEventType === 'DETACHED'
      );
    },
    hasYamlErrors() {
      return this.pipeline?.flags?.yaml_errors || this.pipeline?.yamlErrors;
    },
    hasFailureReason() {
      return this.pipeline?.flags?.failure_reason || Boolean(this.pipeline?.failureReason);
    },
    failureReason() {
      return this.pipeline?.failure_reason || this.pipeline?.failureReason;
    },
    autoDevopsSource() {
      return this.pipeline?.flags?.auto_devops || this.pipeline?.configSource === 'AUTO_DEVOPS';
    },
    stuck() {
      return this.pipeline?.flags?.stuck || this.pipeline?.stuck;
    },
    isAgentSession() {
      return this.pipeline?.source === AGENT_SESSION_ORIGIN;
    },
  },
  buttonClass: '!gl-cursor-default gl-rounded-pill gl-border-none gl-bg-transparent gl-p-0',
};
</script>
<template>
  <div class="gl-mt-1 gl-leading-24">
    <gl-badge
      v-if="isScheduled"
      v-gl-tooltip
      :href="pipelineSchedulesPath"
      target="__blank"
      :title="__('This pipeline was created by a schedule.')"
      variant="info"
      data-testid="pipeline-url-scheduled"
      >{{ __('scheduled') }}</gl-badge
    >
    <button
      v-if="isTriggered"
      v-gl-tooltip
      :class="$options.buttonClass"
      :title="__('This pipeline was created by an API call authenticated with a trigger token')"
      data-testid="pipeline-url-triggered"
    >
      <gl-badge variant="info">{{ __('trigger token') }}</gl-badge>
    </button>

    <button
      v-if="hasLatestFlag"
      v-gl-tooltip
      :class="$options.buttonClass"
      :title="__('Latest pipeline for the most recent commit on this ref')"
      data-testid="pipeline-url-latest"
    >
      <gl-badge variant="success">{{ __('latest') }}</gl-badge>
    </button>

    <button
      v-if="isMergeTrainPipeline"
      v-gl-tooltip
      :title="
        s__(
          'Pipeline|This pipeline ran on the contents of the merge request combined with the contents of all other merge requests queued for merging into the target branch.',
        )
      "
      :class="$options.buttonClass"
      data-testid="pipeline-url-train"
    >
      <gl-badge variant="info">{{ s__('Pipeline|merge train') }}</gl-badge>
    </button>

    <button
      v-if="hasYamlErrors"
      v-gl-tooltip
      :title="pipeline.yaml_errors"
      :class="$options.buttonClass"
      data-testid="pipeline-url-yaml"
    >
      <gl-badge variant="danger">{{ __('yaml invalid') }}</gl-badge>
    </button>

    <button
      v-if="hasFailureReason"
      v-gl-tooltip
      :title="failureReason"
      :class="$options.buttonClass"
      data-testid="pipeline-url-failure"
    >
      <gl-badge variant="danger">{{ __('error') }}</gl-badge>
    </button>
    <template v-if="autoDevopsSource">
      <gl-link
        :id="autoDevopsTagId"
        tabindex="0"
        data-testid="pipeline-url-autodevops"
        role="button"
      >
        <gl-badge variant="info">
          {{ __('Auto DevOps') }}
        </gl-badge>
      </gl-link>
      <gl-popover :target="autoDevopsTagId" triggers="focus" placement="top">
        <template #title>
          <div class="gl-font-normal gl-leading-normal">
            <gl-sprintf
              :message="
                __(
                  'This pipeline makes use of a predefined CI/CD configuration enabled by %{strongStart}Auto DevOps.%{strongEnd}',
                )
              "
            >
              <template #strong="{ content }">
                <b>{{ content }}</b>
              </template>
            </gl-sprintf>
          </div>
        </template>
        <gl-link
          :href="autoDevopsHelpPath"
          data-testid="pipeline-url-autodevops-link"
          target="_blank"
        >
          {{ __('Learn more about Auto DevOps') }}
        </gl-link>
      </gl-popover>
    </template>

    <gl-badge v-if="stuck" variant="warning" data-testid="pipeline-url-stuck">{{
      __('stuck')
    }}</gl-badge>

    <button
      v-if="showTagBadge"
      v-gl-tooltip
      :title="s__(`Pipeline|This pipeline ran for a tag.`)"
      :class="$options.buttonClass"
      data-testid="pipeline-url-tag"
    >
      <gl-badge variant="info">{{ s__('Pipeline|tag') }}</gl-badge>
    </button>

    <button
      v-if="showBranchBadge"
      v-gl-tooltip
      :title="s__(`Pipeline|This pipeline ran for a branch.`)"
      :class="$options.buttonClass"
      data-testid="pipeline-url-branch"
    >
      <gl-badge variant="info">{{ s__('Pipeline|branch') }}</gl-badge>
    </button>
    <button
      v-if="isDetached"
      v-gl-tooltip
      :title="
        s__(
          `Pipeline|This pipeline ran on the contents of the merge request's source branch, not the target branch.`,
        )
      "
      :class="$options.buttonClass"
      data-testid="pipeline-url-detached"
    >
      <gl-badge variant="info">{{ s__('Pipeline|merge request') }}</gl-badge>
    </button>
    <button
      v-if="showMergedResultsBadge"
      v-gl-tooltip
      :title="
        s__(
          `Pipeline|This pipeline ran on the contents of the merge request combined with the contents of the target branch.`,
        )
      "
      :class="$options.buttonClass"
      data-testid="pipeline-url-merged-results"
    >
      <gl-badge variant="info">{{ s__('Pipeline|merged results') }}</gl-badge>
    </button>
    <button
      v-if="isForked"
      v-gl-tooltip
      :title="__('Pipeline ran in fork of project')"
      :class="$options.buttonClass"
      data-testid="pipeline-url-fork"
    >
      <gl-badge variant="info">{{ __('fork') }}</gl-badge>
    </button>
    <button
      v-if="isApi"
      v-gl-tooltip
      :title="__('This pipeline was triggered using the api')"
      :class="$options.buttonClass"
      data-testid="pipeline-api-badge"
    >
      <gl-badge variant="info">{{ s__('Pipeline|api') }}</gl-badge>
    </button>
    <button
      v-if="isAgentSession"
      v-gl-tooltip
      :title="__('This pipeline ran for an agent session')"
      :class="$options.buttonClass"
      data-testid="pipeline-agent-session-badge"
    >
      <gl-badge variant="info">{{ s__('Pipeline|agent session') }}</gl-badge>
    </button>
  </div>
</template>
