<script>
import { GlIcon, GlLink, GlPopover, GlSprintf, GlTooltipDirective, GlBadge } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';
import { SCHEDULE_ORIGIN } from '../../constants';

export default {
  components: {
    GlIcon,
    GlLink,
    GlPopover,
    GlSprintf,
    GlBadge,
    TooltipOnTruncate,
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
    pipelineKey: {
      type: String,
      required: true,
    },
    viewType: {
      type: String,
      required: true,
    },
  },
  computed: {
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
    mergeRequestRef() {
      return this.pipeline?.merge_request;
    },
    commitRef() {
      return this.pipeline?.ref;
    },
    commitTag() {
      return this.commitRef?.tag;
    },
    commitUrl() {
      return this.pipeline?.commit?.commit_path;
    },
    commitShortSha() {
      return this.pipeline?.commit?.short_id;
    },
    refUrl() {
      return this.commitRef?.ref_url || this.commitRef?.path;
    },
    tooltipTitle() {
      return this.mergeRequestRef?.title || this.commitRef?.name;
    },
    commitAuthor() {
      let commitAuthorInformation;
      const pipelineCommit = this.pipeline?.commit;
      const pipelineCommitAuthor = pipelineCommit?.author;

      if (!pipelineCommit) {
        return null;
      }

      // 1. person who is an author of a commit might be a GitLab user
      if (pipelineCommitAuthor) {
        // 2. if person who is an author of a commit is a GitLab user
        // they can have a GitLab avatar
        if (pipelineCommitAuthor?.avatar_url) {
          commitAuthorInformation = pipelineCommitAuthor;

          // 3. If GitLab user does not have avatar, they might have a Gravatar
        } else if (pipelineCommit.author_gravatar_url) {
          commitAuthorInformation = {
            ...pipelineCommitAuthor,
            avatar_url: pipelineCommit.author_gravatar_url,
          };
        }
        // 4. If committer is not a GitLab User, they can have a Gravatar
      } else {
        commitAuthorInformation = {
          avatar_url: pipelineCommit.author_gravatar_url,
          path: `mailto:${pipelineCommit.author_email}`,
          username: pipelineCommit.author_name,
        };
      }

      return commitAuthorInformation;
    },
    commitIcon() {
      let name = '';

      if (this.commitTag) {
        name = 'tag';
      } else if (this.mergeRequestRef) {
        name = 'git-merge';
      } else {
        name = 'branch';
      }

      return name;
    },
    commitTitle() {
      return this.pipeline?.commit?.title;
    },
    hasAuthor() {
      return (
        this.commitAuthor?.avatar_url && this.commitAuthor?.path && this.commitAuthor?.username
      );
    },
    userImageAltDescription() {
      return this.commitAuthor?.username
        ? sprintf(__("%{username}'s avatar"), { username: this.commitAuthor.username })
        : null;
    },
    rearrangePipelinesTable() {
      return this.glFeatures?.rearrangePipelinesTable;
    },
  },
};
</script>
<template>
  <div class="pipeline-tags" data-testid="pipeline-url-table-cell">
    <template v-if="rearrangePipelinesTable">
      <div class="commit-title gl-mb-2" data-testid="commit-title-container">
        <span v-if="commitTitle" class="gl-display-flex">
          <tooltip-on-truncate :title="commitTitle" class="flex-truncate-child gl-flex-grow-1">
            <gl-link
              :href="commitUrl"
              class="commit-row-message gl-text-gray-900"
              data-testid="commit-title"
              >{{ commitTitle }}</gl-link
            >
          </tooltip-on-truncate>
        </span>
        <span v-else>{{ __("Can't find HEAD commit for this branch") }}</span>
      </div>
      <div class="gl-mb-2">
        <gl-link
          :href="pipeline.path"
          class="gl-text-decoration-underline gl-text-blue-600!"
          data-testid="pipeline-url-link"
          data-qa-selector="pipeline_url_link"
        >
          #{{ pipeline[pipelineKey] }}
        </gl-link>
        <!--Commit row-->
        <div class="icon-container gl-display-inline-block">
          <gl-icon :name="commitIcon" />
        </div>
        <tooltip-on-truncate :title="tooltipTitle" truncate-target="child" placement="top">
          <gl-link
            v-if="mergeRequestRef"
            :href="mergeRequestRef.path"
            class="ref-name"
            data-testid="merge-request-ref"
            >{{ mergeRequestRef.iid }}</gl-link
          >
          <gl-link v-else :href="refUrl" class="ref-name" data-testid="commit-ref-name">{{
            commitRef.name
          }}</gl-link>
        </tooltip-on-truncate>
        <gl-icon name="commit" class="commit-icon" />

        <gl-link :href="commitUrl" class="commit-sha mr-0" data-testid="commit-short-sha">{{
          commitShortSha
        }}</gl-link>
        <!--End of commit row-->
      </div>
    </template>
    <gl-link
      v-if="!rearrangePipelinesTable"
      :href="pipeline.path"
      class="gl-text-decoration-underline"
      data-testid="pipeline-url-link"
      data-qa-selector="pipeline_url_link"
    >
      #{{ pipeline[pipelineKey] }}
    </gl-link>
    <div class="label-container gl-mt-1">
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
