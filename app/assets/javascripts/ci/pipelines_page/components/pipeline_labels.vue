<script>
import { GlLink, GlPopover, GlSprintf, GlTooltipDirective, GlBadge } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { SCHEDULE_ORIGIN, API_ORIGIN, TRIGGER_ORIGIN } from '../constants';

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
      return (
        this.pipeline.flags.merged_result_pipeline && !this.pipeline.flags.merge_train_pipeline
      );
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
  },
};
</script>
<template>
  <div class="label-container gl-mt-1 gl-flex gl-flex-wrap gl-gap-2">
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
    <gl-badge
      v-if="isTriggered"
      v-gl-tooltip
      :title="__('This pipeline was created by an API call authenticated with a trigger token')"
      variant="info"
      data-testid="pipeline-url-triggered"
      >{{ __('trigger token') }}</gl-badge
    >
    <gl-badge
      v-if="pipeline.flags.latest"
      v-gl-tooltip
      :title="__('Latest pipeline for the most recent commit on this branch')"
      variant="success"
      data-testid="pipeline-url-latest"
      >{{ __('latest') }}</gl-badge
    >
    <gl-badge
      v-if="pipeline.flags.merge_train_pipeline"
      v-gl-tooltip
      :title="
        s__(
          'Pipeline|This pipeline ran on the contents of the merge request combined with the contents of all other merge requests queued for merging into the target branch.',
        )
      "
      variant="info"
      data-testid="pipeline-url-train"
      >{{ s__('Pipeline|merge train') }}</gl-badge
    >
    <gl-badge
      v-if="pipeline.flags.yaml_errors"
      v-gl-tooltip
      :title="pipeline.yaml_errors"
      variant="danger"
      data-testid="pipeline-url-yaml"
      >{{ __('yaml invalid') }}</gl-badge
    >
    <gl-badge
      v-if="pipeline.flags.failure_reason"
      v-gl-tooltip
      :title="pipeline.failure_reason"
      variant="danger"
      data-testid="pipeline-url-failure"
      >{{ __('error') }}</gl-badge
    >
    <template v-if="pipeline.flags.auto_devops">
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

    <gl-badge v-if="pipeline.flags.stuck" variant="warning" data-testid="pipeline-url-stuck">{{
      __('stuck')
    }}</gl-badge>
    <gl-badge
      v-if="pipeline.flags.detached_merge_request_pipeline"
      v-gl-tooltip
      :title="
        s__(
          `Pipeline|This pipeline ran on the contents of the merge request's source branch, not the target branch.`,
        )
      "
      variant="info"
      data-testid="pipeline-url-detached"
      >{{ s__('Pipeline|merge request') }}</gl-badge
    >
    <gl-badge
      v-if="showMergedResultsBadge"
      v-gl-tooltip
      :title="
        s__(
          `Pipeline|This pipeline ran on the contents of the merge request combined with the contents of the target branch.`,
        )
      "
      variant="info"
      data-testid="pipeline-url-merged-results"
      >{{ s__('Pipeline|merged results') }}</gl-badge
    >
    <gl-badge
      v-if="isForked"
      v-gl-tooltip
      :title="__('Pipeline ran in fork of project')"
      variant="info"
      data-testid="pipeline-url-fork"
      >{{ __('fork') }}</gl-badge
    >
    <gl-badge
      v-if="isApi"
      v-gl-tooltip
      :title="__('This pipeline was triggered using the api')"
      variant="info"
      data-testid="pipeline-api-badge"
      >{{ s__('Pipeline|api') }}</gl-badge
    >
  </div>
</template>
