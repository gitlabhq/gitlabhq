<script>
import { GlIcon, GlLink, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import Tracking from '~/tracking';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import TooltipOnTruncateDirective from '~/vue_shared/directives/tooltip_on_truncate';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import { ICONS, PIPELINE_ID_KEY, PIPELINE_IID_KEY, TRACKING_CATEGORIES } from '~/ci/constants';
import CommitPopover from '~/vue_shared/components/commit_popover.vue';
import PipelineLabels from './pipeline_labels.vue';

export default {
  name: 'PipelineUrl',
  components: {
    CommitPopover,
    GlIcon,
    GlLink,
    PipelineLabels,
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
      return (
        this.pipeline?.commit?.commit_path ||
        this.pipeline?.commit?.webPath ||
        this.pipeline?.commitPath
      );
    },
    commitShortSha() {
      return this.pipeline?.commit?.short_id || this.pipeline?.commit?.shortId;
    },
    popoverTargetId() {
      return `pipeline-commit-popover-${this.commitShortSha}`;
    },
    refUrl() {
      return this.commitRef?.ref_url || this.commitRef?.path || `commits/${this.pipeline?.ref}`;
    },
    commitAuthor() {
      const pipelineCommit = this.pipeline?.commit;
      const pipelineCommitAuthor = pipelineCommit?.author;

      // 1. The author is a GitLab user with an avatar
      if (pipelineCommitAuthor?.avatar_url || pipelineCommitAuthor?.avatarUrl) {
        return pipelineCommitAuthor;
      }

      // 2. The author is a GitLab user without an avatar; REST provides a Gravatar for the commit email
      if (pipelineCommitAuthor) {
        if (!pipelineCommit.author_gravatar_url) {
          return null;
        }

        return { ...pipelineCommitAuthor, avatar_url: pipelineCommit.author_gravatar_url };
      }

      // 3. The author is not a GitLab user, or `commit` is not readable: use the commit's author fields
      const name = pipelineCommit?.author_name || this.pipeline?.commitAuthorName;

      if (!name) {
        return null;
      }

      return {
        avatar_url: pipelineCommit?.author_gravatar_url || this.pipeline?.commitAuthorGravatar,
        path: pipelineCommit?.author_email && `mailto:${pipelineCommit.author_email}`,
        username: name,
        name,
      };
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
    pipelineId() {
      return getIdFromGraphQLId(this.pipeline[this.pipelineIdType]);
    },
    pipelineName() {
      return this.pipeline?.name || '';
    },
    pipelineSecondaryLink() {
      const pipelineSchedule = this.pipeline?.pipelineSchedule || this.pipeline?.pipeline_schedule;

      if (pipelineSchedule) {
        return {
          text: pipelineSchedule.description,
          href: pipelineSchedule.editPath || pipelineSchedule.path,
        };
      }

      const commitTitle = this.pipeline?.commit?.title || this.pipeline?.commitTitle;

      if (commitTitle) {
        return {
          text: commitTitle,
          href: this.commitUrl,
          trackingAction: 'click_commit_title',
        };
      }

      return null;
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
  <div data-testid="pipeline-url-table-cell">
    <gl-link
      v-tooltip-on-truncate
      :href="pipeline.path"
      class="gl-mb-2 gl-block gl-truncate"
      data-testid="pipeline-url-link"
      @click="trackClick('click_pipeline_id')"
      >#{{ pipelineId }} {{ pipelineName }}</gl-link
    >

    <div class="gl-mb-2">
      <gl-link
        v-if="pipelineSecondaryLink"
        v-tooltip-on-truncate
        class="gl-mb-2 gl-block gl-truncate"
        :href="pipelineSecondaryLink.href"
        data-testid="pipeline-identifier-link"
        @click="
          pipelineSecondaryLink.trackingAction && trackClick(pipelineSecondaryLink.trackingAction)
        "
      >
        {{ pipelineSecondaryLink.text }}
      </gl-link>
      <div
        v-else
        v-tooltip-on-truncate
        class="gl-mb-2 gl-truncate gl-text-subtle"
        data-testid="pipeline-identifier-missing-message"
      >
        {{ __("Can't find HEAD commit for this branch") }}
      </div>

      <!--Commit row-->
      <div class="gl-inline-block gl-rounded-base gl-bg-strong gl-px-2">
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
          :id="popoverTargetId"
          :href="commitUrl"
          class="gl-mr-0 gl-font-monospace gl-text-sm gl-text-subtle hover:gl-text-subtle"
          data-testid="commit-short-sha"
          @click="trackClick('click_commit_sha')"
          >{{ commitShortSha }}</gl-link
        >
        <commit-popover
          v-if="pipeline.commit"
          :popover-target-id="popoverTargetId"
          :commit="pipeline.commit"
          class="gl-z-3"
        />
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
