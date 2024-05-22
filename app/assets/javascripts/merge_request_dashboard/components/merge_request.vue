<script>
import { GlLink, GlSprintf, GlIcon, GlLabel, GlTooltipDirective } from '@gitlab/ui';
import ApprovalCount from 'ee_component/merge_request_dashboard/components/approval_count.vue';
import { __, sprintf } from '~/locale';
import isShowingLabelsQuery from '~/graphql_shared/client/is_showing_labels.query.graphql';
import SafeHtml from '~/vue_shared/directives/safe_html';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import { isScopedLabel } from '~/lib/utils/common_utils';

export default {
  apollo: {
    isShowingLabels: {
      query: isShowingLabelsQuery,
      update: (data) => data.isShowingLabels,
    },
  },
  components: {
    GlLink,
    GlSprintf,
    GlIcon,
    GlLabel,
    CiIcon,
    TimeAgoTooltip,
    UserAvatarLink,
    ApprovalCount,
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
  },
  data() {
    return {
      isShowingLabels: true,
    };
  },
  methods: {
    showScopedLabel(label) {
      return isScopedLabel(label);
    },
    assigneeTitle(assignee) {
      return sprintf(__('Assigned to %{assignee}'), { assignee: assignee.name });
    },
    reviewerTitle(reviewer) {
      return sprintf(__('Review requested %{reviewer}'), { reviewer: reviewer.name });
    },
  },
};
</script>

<template>
  <div class="gl-bg-white gl-p-5 gl-rounded-base">
    <div
      class="gl-display-flex"
      :class="{ 'gl-mb-2': mergeRequest.labels.length && isShowingLabels }"
    >
      <div class="gl-display-flex gl-flex-direction-column">
        <h4 class="gl-mb-0 gl-mt-0 gl-font-base">
          <gl-link
            v-safe-html="mergeRequest.titleHtml"
            :href="mergeRequest.webUrl"
            class="gl-text-body gl-hover-text-gray-900"
          />
        </h4>
        <div class="gl-font-sm gl-mt-2 gl-text-secondary">
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
                <gl-icon :size="16" class="gl-ml-2" name="milestone" />
                {{ mergeRequest.milestone.title }}
              </template>
            </template>
          </gl-sprintf>
        </div>
      </div>
      <div class="gl-ml-auto gl-display-flex gl-flex-direction-column">
        <ul class="gl-display-flex gl-justify-content-end gl-m-0 gl-p-0 gl-list-none">
          <li v-if="mergeRequest.headPipeline && mergeRequest.headPipeline.detailedStatus">
            <ci-icon :status="mergeRequest.headPipeline.detailedStatus" use-link show-tooltip />
          </li>
          <li v-if="mergeRequest.assignees.nodes.length" class="gl-ml-4">
            <user-avatar-link
              v-for="(assignee, index) in mergeRequest.assignees.nodes"
              :key="`assignee_${assignee.id}`"
              :link-href="assignee.webUrl"
              :img-src="assignee.avatarUrl"
              :img-size="24"
              :tooltip-text="assigneeTitle(assignee)"
              :class="{ 'gl-mr-2': index !== mergeRequest.assignees.nodes.length - 1 }"
            />
          </li>
          <li v-if="mergeRequest.reviewers.nodes.length" class="gl-ml-4">
            <user-avatar-link
              v-for="(reviewer, index) in mergeRequest.reviewers.nodes"
              :key="`reviewer_${reviewer.id}`"
              :link-href="reviewer.webUrl"
              :img-src="reviewer.avatarUrl"
              :img-size="24"
              :tooltip-text="reviewerTitle(reviewer)"
              :class="{ 'gl-mr-2': index !== mergeRequest.reviewers.nodes.length - 1 }"
            />
          </li>
          <li
            v-if="mergeRequest.approvalsRequired || mergeRequest.approved"
            class="gl-ml-4 gl-display-flex gl-align-self-center"
          >
            <approval-count :merge-request="mergeRequest" />
          </li>
          <li
            v-if="mergeRequest.userDiscussionsCount"
            v-gl-tooltip="__('Comments')"
            class="gl-align-self-center gl-ml-4"
          >
            <gl-icon name="comments" class="!gl-align-middle" />
            {{ mergeRequest.userDiscussionsCount }}
          </li>
        </ul>
        <div
          v-if="mergeRequest.updatedAt"
          class="gl-font-sm gl-mt-2 gl-text-secondary gl-text-right"
        >
          <gl-sprintf :message="__('Updated at %{updatedAt}')">
            <template #updatedAt><time-ago-tooltip :time="mergeRequest.updatedAt" /></template>
          </gl-sprintf>
        </div>
      </div>
    </div>
    <div v-if="isShowingLabels">
      <gl-label
        v-for="label in mergeRequest.labels.nodes"
        :key="label.id"
        :background-color="label.color"
        :title="label.title"
        :description="label.description"
        size="sm"
        :scoped="showScopedLabel(label)"
        class="gl-mr-2"
      />
    </div>
  </div>
</template>
