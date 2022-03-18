<script>
import { GlIcon, GlLink, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';
import { ICONS } from '../../constants';
import PipelineLabels from './pipeline_labels.vue';

export default {
  components: {
    GlIcon,
    GlLink,
    PipelineLabels,
    TooltipOnTruncate,
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
    pipelineKey: {
      type: String,
      required: true,
    },
  },
  computed: {
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
        name = ICONS.TAG;
      } else if (this.mergeRequestRef) {
        name = ICONS.MR;
      } else {
        name = ICONS.BRANCH;
      }

      return name;
    },
    commitIconTooltipTitle() {
      switch (this.commitIcon) {
        case ICONS.TAG:
          return __('Tag');
        case ICONS.MR:
          return __('Merge Request');
        default:
          return __('Branch');
      }
    },
    commitTitle() {
      return this.pipeline?.commit?.title;
    },
  },
};
</script>
<template>
  <div class="pipeline-tags" data-testid="pipeline-url-table-cell">
    <div class="commit-title gl-mb-2" data-testid="commit-title-container">
      <span v-if="commitTitle" class="gl-display-flex">
        <tooltip-on-truncate :title="commitTitle" class="gl-flex-grow-1 gl-text-truncate">
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
        class="gl-text-decoration-underline gl-text-blue-600! gl-mr-3"
        data-testid="pipeline-url-link"
        data-qa-selector="pipeline_url_link"
      >
        #{{ pipeline[pipelineKey] }}
      </gl-link>
      <!--Commit row-->
      <div class="icon-container gl-display-inline-block gl-mr-1">
        <gl-icon
          v-gl-tooltip
          :name="commitIcon"
          :title="commitIconTooltipTitle"
          data-testid="commit-icon-type"
        />
      </div>
      <tooltip-on-truncate :title="tooltipTitle" truncate-target="child" placement="top">
        <gl-link
          v-if="mergeRequestRef"
          :href="mergeRequestRef.path"
          class="ref-name gl-mr-3"
          data-testid="merge-request-ref"
          >{{ mergeRequestRef.iid }}</gl-link
        >
        <gl-link v-else :href="refUrl" class="ref-name gl-mr-3" data-testid="commit-ref-name">{{
          commitRef.name
        }}</gl-link>
      </tooltip-on-truncate>
      <gl-icon
        v-gl-tooltip
        name="commit"
        class="commit-icon gl-mr-1"
        :title="__('Commit')"
        data-testid="commit-icon"
      />
      <gl-link :href="commitUrl" class="commit-sha mr-0" data-testid="commit-short-sha">{{
        commitShortSha
      }}</gl-link>
      <!--End of commit row-->
    </div>
    <pipeline-labels :pipeline-schedule-url="pipelineScheduleUrl" :pipeline="pipeline" />
  </div>
</template>
