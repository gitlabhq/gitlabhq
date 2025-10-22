<script>
import { GlIcon, GlLink, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import Tracking from '~/tracking';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';
import TooltipOnTruncateDirective from '~/vue_shared/directives/tooltip_on_truncate';
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
    TooltipOnTruncate: TooltipOnTruncateDirective,
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
  },
  computed: {
    mergeRequestRef() {
      return this.pipeline?.merge_request || this.pipeline?.mergeRequest;
    },
    commitRef() {
      return this.pipeline?.ref;
    },
    commitTag() {
      return this.commitRef?.tag || this.pipeline?.type === 'tag';
    },
    commitUrl() {
      return this.pipeline?.commit?.commit_path || this.pipeline?.commit?.webUrl;
    },
    commitShortSha() {
      return this.pipeline?.commit?.short_id || this.pipeline?.commit?.shortId;
    },
    refUrl() {
      return this.commitRef?.ref_url || this.commitRef?.path || this.pipeline?.refPath;
    },
    tooltipTitle() {
      return this.mergeRequestRef?.title || this.commitRef?.name || this.pipeline?.refText;
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

        if (pipelineCommitAuthor?.avatar_url || pipelineCommitAuthor?.avatarUrl) {
          commitAuthorInformation = pipelineCommitAuthor;

          // 3. If GitLab user does not have avatar, they might have a Gravatar
        } else if (pipelineCommit?.author_gravatar_url || pipelineCommitAuthor?.avatarUrl) {
          commitAuthorInformation = {
            ...pipelineCommitAuthor,
            avatar_url: pipelineCommit?.author_gravatar_url || pipelineCommitAuthor?.avatarUrl,
          };
        }
        // 4. If committer is not a GitLab User, they can have a Gravatar
      } else {
        commitAuthorInformation = {
          avatar_url: pipelineCommit?.author_gravatar_url || pipelineCommitAuthor?.avatarUrl,
          path: `mailto:${pipelineCommit?.author_email || pipelineCommitAuthor?.publicEmail}`,
          username: pipelineCommit?.author_name || pipelineCommitAuthor?.name,
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

    pipelineLink() {
      const { name, path, pipeline_schedule: pipelineSchedule } = this.pipeline || {};

      // pipeline name should take priority over
      // pipeline schedule description
      if (name) {
        return {
          text: name,
          href: path,
        };
      }

      if (pipelineSchedule) {
        return {
          text: pipelineSchedule.description,
          href: pipelineSchedule.path,
        };
      }

      if (this.pipeline?.commit) {
        return {
          text: this.pipeline?.commit?.title,
          href: this.commitUrl,
          trackingAction: 'click_commit_title',
        };
      }

      return null;
    },
    pipelineId() {
      return getIdFromGraphQLId(this.pipeline[this.pipelineIdType]);
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
    <gl-link
      v-if="pipelineLink"
      v-tooltip-on-truncate
      class="gl-mb-2 gl-block gl-truncate"
      :href="pipelineLink.href"
      data-testid="pipeline-identifier-link"
      @click="pipelineLink.trackingAction && trackClick(pipelineLink.trackingAction)"
    >
      {{ pipelineLink.text }}
    </gl-link>
    <div
      v-else
      v-tooltip-on-truncate
      class="gl-mb-2 gl-truncate gl-text-subtle"
      data-testid="pipeline-identifier-missing-message"
    >
      {{ __("Can't find HEAD commit for this branch") }}
    </div>

    <div class="gl-mb-2">
      <gl-link
        :href="pipeline.path"
        class="gl-mr-1"
        data-testid="pipeline-url-link"
        @click="trackClick('click_pipeline_id')"
        >#{{ pipelineId }}</gl-link
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
            :href="mergeRequestRef.path || mergeRequestRef.webPath"
            class="gl-font-monospace gl-text-sm gl-text-subtle hover:gl-text-subtle"
            data-testid="merge-request-ref"
            @click="trackClick('click_mr_ref')"
            >{{ mergeRequestRef.iid }}</gl-link
          >
          <gl-link
            v-else
            :href="refUrl"
            class="gl-font-monospace gl-text-sm gl-text-subtle hover:gl-text-subtle"
            data-testid="commit-ref-name"
            @click="trackClick('click_commit_name')"
            >{{ commitRef.name || pipeline.ref }}</gl-link
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
          class="gl-mr-0 gl-font-monospace gl-text-sm gl-text-subtle hover:gl-text-subtle"
          data-testid="commit-short-sha"
          @click="trackClick('click_commit_sha')"
          >{{ commitShortSha }}</gl-link
        >
      </div>

      <user-avatar-link
        v-if="commitAuthor"
        :link-href="commitAuthor.path || commitAuthor.webPath"
        :img-src="commitAuthor.avatar_url || commitAuthor.avatarUrl"
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
