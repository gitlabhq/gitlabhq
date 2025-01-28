<script>
import { GlIcon, GlLink, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import Tracking from '~/tracking';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import { ICONS, PIPELINE_ID_KEY, PIPELINE_IID_KEY, TRACKING_CATEGORIES } from '~/ci/constants';
import PipelineLabels from './pipeline_labels.vue';

export default {
  components: {
    GlIcon,
    GlLink,
    PipelineLabels,
    TooltipOnTruncate,
    UserAvatarLink,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [Tracking.mixin()],
  props: {
    pipeline: {
      type: Object,
      required: true,
    },
    pipelineIdType: {
      type: String,
      required: false,
      default: PIPELINE_ID_KEY,
      validator(value) {
        return value === PIPELINE_IID_KEY || value === PIPELINE_ID_KEY;
      },
    },
    refClass: {
      type: String,
      required: false,
      default: '',
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
        } else if (pipelineCommit?.author_gravatar_url) {
          commitAuthorInformation = {
            ...pipelineCommitAuthor,
            avatar_url: pipelineCommit.author_gravatar_url,
          };
        }
        // 4. If committer is not a GitLab User, they can have a Gravatar
      } else {
        commitAuthorInformation = {
          avatar_url: pipelineCommit?.author_gravatar_url,
          path: `mailto:${pipelineCommit?.author_email}`,
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
    pipelineIdentifier() {
      const { name, path, pipeline_schedule: pipelineSchedule } = this.pipeline || {};

      // pipeline name should take priority over
      // pipeline schedule description
      if (name) {
        return {
          text: name,
          link: path,
        };
      }

      if (pipelineSchedule) {
        return {
          text: pipelineSchedule.description,
          link: pipelineSchedule.path,
        };
      }

      return false;
    },
  },
  methods: {
    trackClick(action) {
      this.track(action, { label: TRACKING_CATEGORIES.table });
    },
  },
};
</script>
<template>
  <div class="pipeline-tags" data-testid="pipeline-url-table-cell">
    <div v-if="pipelineIdentifier" class="gl-mb-2" data-testid="pipeline-identifier-container">
      <span class="gl-flex">
        <tooltip-on-truncate
          :title="pipelineIdentifier.text"
          class="gl-grow gl-truncate gl-text-default"
        >
          <gl-link :href="pipelineIdentifier.link" data-testid="pipeline-identifier-link">{{
            pipelineIdentifier.text
          }}</gl-link>
        </tooltip-on-truncate>
      </span>
    </div>

    <div
      v-if="!pipelineIdentifier"
      class="commit-title gl-mb-2"
      data-testid="commit-title-container"
    >
      <span v-if="commitTitle" class="gl-flex">
        <tooltip-on-truncate
          :title="commitTitle"
          class="-gl-mb-3 -gl-ml-3 -gl-mr-3 -gl-mt-3 gl-grow gl-truncate gl-p-3"
        >
          <gl-link
            :href="commitUrl"
            class="commit-row-message"
            data-testid="commit-title"
            @click="trackClick('click_commit_title')"
            >{{ commitTitle }}</gl-link
          >
        </tooltip-on-truncate>
      </span>
      <span v-else class="gl-text-subtle">{{ __("Can't find HEAD commit for this branch") }}</span>
    </div>

    <div class="gl-mb-2">
      <gl-link
        :href="pipeline.path"
        class="gl-mr-1"
        data-testid="pipeline-url-link"
        @click="trackClick('click_pipeline_id')"
        >#{{ pipeline[pipelineIdType] }}</gl-link
      >
      <!--Commit row-->
      <div class="gl-inline-flex gl-rounded-base gl-bg-strong gl-px-2">
        <tooltip-on-truncate :title="tooltipTitle" truncate-target="child" placement="top">
          <gl-icon
            v-gl-tooltip
            :name="commitIcon"
            :title="commitIconTooltipTitle"
            :size="12"
            data-testid="commit-icon-type"
            variant="subtle"
          />
          <gl-link
            v-if="mergeRequestRef"
            :href="mergeRequestRef.path"
            class="gl-text-sm gl-text-subtle gl-font-monospace hover:gl-text-subtle"
            :class="refClass"
            data-testid="merge-request-ref"
            @click="trackClick('click_mr_ref')"
            >{{ mergeRequestRef.iid }}</gl-link
          >
          <gl-link
            v-else
            :href="refUrl"
            class="gl-text-sm gl-text-subtle gl-font-monospace hover:gl-text-subtle"
            :class="refClass"
            data-testid="commit-ref-name"
            @click="trackClick('click_commit_name')"
            >{{ commitRef.name }}</gl-link
          >
        </tooltip-on-truncate>
      </div>

      <div class="gl-inline-block gl-rounded-base gl-bg-strong gl-px-2 gl-text-sm">
        <gl-icon
          v-gl-tooltip
          name="commit"
          class="gl-mr-1"
          :title="__('Commit')"
          :size="12"
          data-testid="commit-icon"
          variant="subtle"
        />
        <gl-link
          :href="commitUrl"
          class="gl-mr-0 gl-text-sm gl-text-subtle gl-font-monospace hover:gl-text-subtle"
          data-testid="commit-short-sha"
          @click="trackClick('click_commit_sha')"
          >{{ commitShortSha }}</gl-link
        >
      </div>

      <user-avatar-link
        v-if="commitAuthor"
        :link-href="commitAuthor.path"
        :img-src="commitAuthor.avatar_url"
        :img-size="16"
        :img-alt="commitAuthor.name"
        :tooltip-text="commitAuthor.name"
        class="gl-ml-1"
      />
      <!--End of commit row-->
    </div>
    <pipeline-labels :pipeline="pipeline" />
  </div>
</template>
