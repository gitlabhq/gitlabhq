<script>
import { GlLink, GlPopover, GlSprintf, GlTooltipDirective, GlBadge } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { SCHEDULE_ORIGIN } from '../../constants';

export default {
  components: {
    GlLink,
    GlPopover,
    GlSprintf,
    GlBadge,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagMixin()],
  inject: {
    targetProjectFullPath: {
      default: '',
    },
  },
  props: {
    pipeline: {
      type: Object,
      required: true,
    },
    pipelineScheduleUrl: {
      type: String,
      required: true,
    },
  },
  computed: {
    user() {
      return this.pipeline.user;
    },
    isScheduled() {
      return this.pipeline.source === SCHEDULE_ORIGIN;
    },
    isInFork() {
      return Boolean(
        this.targetProjectFullPath &&
          this.pipeline?.project?.full_path !== `/${this.targetProjectFullPath}`,
      );
    },
    autoDevopsTagId() {
      return `pipeline-url-autodevops-${this.pipeline.id}`;
    },
    autoDevopsHelpPath() {
      return helpPagePath('topics/autodevops/index.md');
    },
  },
};
</script>
<template>
  <div class="pipeline-tags" data-testid="pipeline-url-table-cell">
    <gl-link
      :href="pipeline.path"
      class="gl-text-decoration-underline"
      data-testid="pipeline-url-link"
      data-qa-selector="pipeline_url_link"
    >
      #{{ pipeline.id }}
    </gl-link>
    <div class="label-container">
      <gl-badge
        v-if="isScheduled"
        v-gl-tooltip
        :href="pipelineScheduleUrl"
        target="__blank"
        :title="__('This pipeline was triggered by a schedule.')"
        variant="info"
        size="sm"
        data-testid="pipeline-url-scheduled"
        >{{ __('Scheduled') }}</gl-badge
      >
      <gl-badge
        v-if="pipeline.flags.latest"
        v-gl-tooltip
        :title="__('Latest pipeline for the most recent commit on this branch')"
        variant="success"
        size="sm"
        data-testid="pipeline-url-latest"
        >{{ __('latest') }}</gl-badge
      >
      <gl-badge
        v-if="pipeline.flags.merge_train_pipeline"
        v-gl-tooltip
        :title="__('This is a merge train pipeline')"
        variant="info"
        size="sm"
        data-testid="pipeline-url-train"
        >{{ __('train') }}</gl-badge
      >
      <gl-badge
        v-if="pipeline.flags.yaml_errors"
        v-gl-tooltip
        :title="pipeline.yaml_errors"
        variant="danger"
        size="sm"
        data-testid="pipeline-url-yaml"
        >{{ __('yaml invalid') }}</gl-badge
      >
      <gl-badge
        v-if="pipeline.flags.failure_reason"
        v-gl-tooltip
        :title="pipeline.failure_reason"
        variant="danger"
        size="sm"
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
          <gl-badge variant="info" size="sm">
            {{ __('Auto DevOps') }}
          </gl-badge>
        </gl-link>
        <gl-popover :target="autoDevopsTagId" triggers="focus" placement="top">
          <template #title>
            <div class="gl-font-weight-normal gl-line-height-normal">
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

      <gl-badge
        v-if="pipeline.flags.stuck"
        variant="warning"
        size="sm"
        data-testid="pipeline-url-stuck"
        >{{ __('stuck') }}</gl-badge
      >
      <gl-badge
        v-if="pipeline.flags.detached_merge_request_pipeline"
        v-gl-tooltip
        :title="
          __(
            'Pipelines for merge requests are configured. A detached pipeline runs in the context of the merge request, and not against the merged result. Learn more in the documentation for Pipelines for Merged Results.',
          )
        "
        variant="info"
        size="sm"
        data-testid="pipeline-url-detached"
        >{{ __('detached') }}</gl-badge
      >
      <gl-badge
        v-if="isInFork"
        v-gl-tooltip
        :title="__('Pipeline ran in fork of project')"
        variant="info"
        size="sm"
        data-testid="pipeline-url-fork"
        >{{ __('fork') }}</gl-badge
      >
    </div>
  </div>
</template>
