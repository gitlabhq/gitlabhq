<script>
import { GlLink, GlSprintf, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import ApprovalCount from 'ee_else_ce/merge_requests/components/approval_count.vue';
import { __, n__, sprintf } from '~/locale';
import SafeHtml from '~/vue_shared/directives/safe_html';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import UserAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image.vue';
import DiscussionsBadge from '~/merge_requests/list/components/discussions_badge.vue';
import AssignedUsers from './assigned_users.vue';
import StatusBadge from './status_badge.vue';

export default {
  components: {
    GlLink,
    GlSprintf,
    GlIcon,
    UserAvatarImage,
    CiIcon,
    TimeAgoTooltip,
    ApprovalCount,
    DiscussionsBadge,
    AssignedUsers,
    StatusBadge,
  },
  directives: {
    SafeHtml,
    GlTooltip: GlTooltipDirective,
  },
  props: {
    mergeRequest: {
      type: Object,
      required: true,
    },
    listId: {
      type: String,
      required: true,
    },
    isLast: {
      type: Boolean,
      required: false,
    },
  },
  computed: {
    statsAriaLabel() {
      const fileAdditions = n__(
        '%d file addition',
        '%d file additions',
        this.mergeRequest.diffStatsSummary.additions,
      );
      const fileDeletions = n__(
        '%d file deletion',
        '%d file deletions',
        this.mergeRequest.diffStatsSummary.deletions,
      );

      return sprintf(__('%{filesChanged}, %{fileAdditions}, %{fileDeletions}'), {
        filesChanged: n__('%d file', '%d files', this.mergeRequest.diffStatsSummary.fileCount),
        fileAdditions,
        fileDeletions,
      });
    },
    isMergeRequestBroken() {
      return (
        this.mergeRequest.state === 'opened' &&
        (this.mergeRequest.commitCount === 0 ||
          !this.mergeRequest.sourceBranchExists ||
          !this.mergeRequest.targetBranchExists ||
          this.mergeRequest.conflicts)
      );
    },
  },
};
</script>

<template>
  <tr :class="{ 'gl-border-b': !isLast }">
    <td class="gl-py-4 gl-pl-5 gl-pr-3 gl-align-top">
      <status-badge :merge-request="mergeRequest" :list-id="listId" />
    </td>
    <td class="gl-px-3 gl-py-4 gl-align-top">
      <gl-link
        :href="mergeRequest.webUrl"
        class="gl-font-bold gl-text-default hover:gl-text-default"
      >
        {{ mergeRequest.title }}
      </gl-link>
      <div class="gl-mb-2 gl-mt-2 gl-text-sm gl-text-subtle">
        <gl-sprintf :message="__('%{reference} %{author} %{stats} %{milestone}')">
          <template #reference>{{ mergeRequest.reference }}</template>
          <template #author>
            <gl-link
              :href="mergeRequest.author.webUrl"
              class="gl-mx-2 gl-inline-flex gl-align-bottom gl-text-subtle"
            >
              <user-avatar-image
                :img-src="mergeRequest.author.avatarUrl"
                img-alt=""
                :size="16"
                lazy
              />
              <span class="gl-sr-only">{{ mergeRequest.author.name }}</span>
            </gl-link>
          </template>
          <template #milestone>
            <template v-if="mergeRequest.milestone">
              <gl-icon :size="16" name="milestone" />
              {{ mergeRequest.milestone.title }}
            </template>
          </template>
          <template #stats>
            <div
              v-if="mergeRequest.diffStatsSummary.fileCount"
              class="gl-mr-2 gl-inline-flex gl-gap-2"
              :aria-label="statsAriaLabel"
              :title="statsAriaLabel"
            >
              <div class="gl-whitespace-nowrap">
                <gl-icon name="doc-new" />
                <span>{{ mergeRequest.diffStatsSummary.fileCount }}</span>
              </div>
              <div class="gl-flex gl-items-center gl-text-success">
                <span>+</span>
                <span>{{ mergeRequest.diffStatsSummary.additions }}</span>
              </div>
              <div class="gl-flex gl-items-center gl-text-danger">
                <span>−</span>
                <span>{{ mergeRequest.diffStatsSummary.deletions }}</span>
              </div>
            </div>
          </template>
        </gl-sprintf>
      </div>
    </td>
    <td class="gl-px-3 gl-py-4 gl-align-top">
      <assigned-users :users="mergeRequest.assignees.nodes" type="ASSIGNEES" />
    </td>
    <td class="gl-px-3 gl-py-4 gl-align-top">
      <assigned-users :users="mergeRequest.reviewers.nodes" type="REVIEWERS" />
    </td>
    <td class="gl-py-4 gl-pl-3 gl-pr-5 gl-align-top">
      <div class="gl-flex gl-justify-end gl-gap-3">
        <gl-icon
          v-if="isMergeRequestBroken"
          v-gl-tooltip
          :title="__('Cannot be merged automatically')"
          name="warning-solid"
          variant="subtle"
          class="gl-mt-1"
          data-testid="mr-broken-badge"
        />
        <discussions-badge
          v-if="mergeRequest.resolvableDiscussionsCount"
          :merge-request="mergeRequest"
        />
        <approval-count :merge-request="mergeRequest" />
        <ci-icon
          v-if="mergeRequest.headPipeline && mergeRequest.headPipeline.detailedStatus"
          :status="mergeRequest.headPipeline.detailedStatus"
          use-link
          show-tooltip
        />
      </div>
      <div class="gl-mt-1 gl-text-right gl-text-sm gl-text-subtle">
        <gl-sprintf :message="__('Updated %{updatedAt}')">
          <template #updatedAt>
            <time-ago-tooltip :time="mergeRequest.updatedAt" />
          </template>
        </gl-sprintf>
      </div>
    </td>
  </tr>
</template>
