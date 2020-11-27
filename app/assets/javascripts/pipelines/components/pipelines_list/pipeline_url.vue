<script>
import { GlLink, GlPopover, GlSprintf, GlTooltipDirective } from '@gitlab/ui';
import { SCHEDULE_ORIGIN } from '../../constants';

export default {
  components: {
    GlLink,
    GlPopover,
    GlSprintf,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
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
    autoDevopsHelpPath: {
      type: String,
      required: true,
    },
  },
  inject: {
    targetProjectFullPath: {
      default: '',
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
  },
};
</script>
<template>
  <div class="table-section section-10 d-none d-md-block pipeline-tags">
    <gl-link
      :href="pipeline.path"
      class="js-pipeline-url-link js-onboarding-pipeline-item"
      data-testid="pipeline-url-link"
      data-qa-selector="pipeline_url_link"
    >
      <span class="pipeline-id">#{{ pipeline.id }}</span>
    </gl-link>
    <div class="label-container">
      <gl-link v-if="isScheduled" :href="pipelineScheduleUrl" target="__blank">
        <span
          v-gl-tooltip
          :title="__('This pipeline was triggered by a schedule.')"
          class="badge badge-info"
          data-testid="pipeline-url-scheduled"
          >{{ __('Scheduled') }}</span
        >
      </gl-link>
      <span
        v-if="pipeline.flags.latest"
        v-gl-tooltip
        :title="__('Latest pipeline for the most recent commit on this branch')"
        class="js-pipeline-url-latest badge badge-success"
        data-testid="pipeline-url-latest"
        >{{ __('latest') }}</span
      >
      <span
        v-if="pipeline.flags.yaml_errors"
        v-gl-tooltip
        :title="pipeline.yaml_errors"
        class="js-pipeline-url-yaml badge badge-danger"
        data-testid="pipeline-url-yaml"
        >{{ __('yaml invalid') }}</span
      >
      <span
        v-if="pipeline.flags.failure_reason"
        v-gl-tooltip
        :title="pipeline.failure_reason"
        class="js-pipeline-url-failure badge badge-danger"
        data-testid="pipeline-url-failure"
        >{{ __('error') }}</span
      >
      <gl-link
        v-if="pipeline.flags.auto_devops"
        :id="`pipeline-url-autodevops-${pipeline.id}`"
        tabindex="0"
        class="js-pipeline-url-autodevops badge badge-info autodevops-badge"
        data-testid="pipeline-url-autodevops"
        role="button"
        >{{ __('Auto DevOps') }}</gl-link
      >
      <gl-popover
        :target="`pipeline-url-autodevops-${pipeline.id}`"
        triggers="focus"
        placement="top"
      >
        <template #title>
          <div class="gl-font-weight-normal gl-line-height-normal">
            <gl-sprintf
              :message="
                __(
                  'This pipeline makes use of a predefined CI/CD configuration enabled by %{strongStart}Auto DevOps.%{strongEnd}',
                )
              "
            >
              <template #strong="{content}">
                <b>{{ content }}</b>
              </template>
            </gl-sprintf>
          </div>
        </template>
        <gl-link :href="autoDevopsHelpPath" target="_blank" rel="noopener noreferrer nofollow">{{
          __('Learn more about Auto DevOps')
        }}</gl-link>
      </gl-popover>
      <span
        v-if="pipeline.flags.stuck"
        class="js-pipeline-url-stuck badge badge-warning"
        data-testid="pipeline-url-stuck"
        >{{ __('stuck') }}</span
      >
      <span
        v-if="pipeline.flags.detached_merge_request_pipeline"
        v-gl-tooltip
        :title="
          __(
            'Pipelines for merge requests are configured. A detached pipeline runs in the context of the merge request, and not against the merged result. Learn more in the documentation for Pipelines for Merged Results.',
          )
        "
        class="js-pipeline-url-detached badge badge-info"
        data-testid="pipeline-url-detached"
        >{{ __('detached') }}</span
      >
      <span
        v-if="isInFork"
        v-gl-tooltip
        :title="__('Pipeline ran in fork of project')"
        class="badge badge-info"
        data-testid="pipeline-url-fork"
        >{{ __('fork') }}</span
      >
    </div>
  </div>
</template>
