<script>
import { GlLink, GlSprintf, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import ApprovalCount from 'ee_else_ce/merge_requests/components/approval_count.vue';
import { __, n__, sprintf } from '~/locale';
import SafeHtml from '~/vue_shared/directives/safe_html';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import AssignedUsers from './assigned_users.vue';

export default {
  components: {
    GlLink,
    GlSprintf,
    GlIcon,
    CiIcon,
    TimeAgoTooltip,
    ApprovalCount,
    AssignedUsers,
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
    isLast: {
      type: Boolean,
      required: false,
    },
  },
  computed: {
    statsAriaLabel() {
      const comments = n__('%d comment', '%d comments', this.mergeRequest.userNotesCount);
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

      return sprintf(__('%{comments}, %{fileAdditions}, %{fileDeletions}'), {
        comments,
        fileAdditions,
        fileDeletions,
      });
    },
  },
};
</script>

<template>
  <tr :class="{ 'gl-border-b': !isLast }">
    <td class="gl-py-4 gl-pl-5 gl-pr-3 gl-align-top">
      <ci-icon
        v-if="mergeRequest.headPipeline && mergeRequest.headPipeline.detailedStatus"
        :status="mergeRequest.headPipeline.detailedStatus"
        use-link
        show-tooltip
      />
      <gl-icon v-else name="dash" />
    </td>
    <td class="gl-px-3 gl-py-4 gl-align-top">
      <approval-count :merge-request="mergeRequest" />
    </td>
    <td class="gl-px-3 gl-py-4 gl-align-top">
      <h4 class="gl-mb-0 gl-mt-0 gl-text-base">
        <gl-link
          v-safe-html="mergeRequest.titleHtml"
          :href="mergeRequest.webUrl"
          class="gl-text-primary hover:gl-text-gray-900"
        />
      </h4>
      <div class="gl-mb-2 gl-mt-2 gl-text-sm gl-text-secondary">
        <gl-sprintf
          :message="__('%{reference} %{divider} created %{createdAt} by %{author} %{milestone}')"
        >
          <template #reference>{{ mergeRequest.reference }}</template>
          <template #divider>&middot;</template>
          <template #createdAt><time-ago-tooltip :time="mergeRequest.createdAt" /></template>
          <template #author>
            <gl-link :href="mergeRequest.author.webUrl" class="gl-text-secondary">
              {{ mergeRequest.author.name }}
            </gl-link>
          </template>
          <template #milestone>
            <template v-if="mergeRequest.milestone">
              &middot;
              <gl-icon :size="16" name="milestone" />
              {{ mergeRequest.milestone.title }}
            </template>
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
      <div class="gl-flex gl-justify-end gl-gap-3" :aria-label="statsAriaLabel">
        <div class="gl-whitespace-nowrap">
          <gl-icon name="comments" class="!gl-align-middle" />
          {{ mergeRequest.userNotesCount }}
        </div>
        <div class="gl-whitespace-nowrap">
          <gl-icon name="doc-code" />
          <span>{{ mergeRequest.diffStatsSummary.fileCount }}</span>
        </div>
        <div class="gl-flex gl-items-center gl-font-bold gl-text-green-600">
          <span>+</span>
          <span>{{ mergeRequest.diffStatsSummary.additions }}</span>
        </div>
        <div class="gl-flex gl-items-center gl-font-bold gl-text-red-500">
          <span>−</span>
          <span>{{ mergeRequest.diffStatsSummary.deletions }}</span>
        </div>
      </div>
      <div class="gl-mt-1 gl-text-right gl-text-sm gl-text-secondary">
        <gl-sprintf :message="__('Updated %{updatedAt}')">
          <template #updatedAt>
            <time-ago-tooltip :time="mergeRequest.updatedAt" />
          </template>
        </gl-sprintf>
      </div>
    </td>
  </tr>
</template>
