<script>
import { GlIcon, GlPopover, GlSkeletonLoader, GlTooltipDirective } from '@gitlab/ui';
import query from 'ee_else_ce/issuable/popover/queries/issue.query.graphql';
import IssueDueDate from '~/boards/components/issue_due_date.vue';
import IssueMilestone from '~/issuable/components/issue_milestone.vue';
import StatusBadge from '~/issuable/components/status_badge.vue';
import { STATUS_CLOSED, TYPE_ISSUE } from '~/issues/constants';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import WorkItemTypeIcon from '~/work_items/components/work_item_type_icon.vue';

export default {
  TYPE_ISSUE,
  components: {
    GlIcon,
    GlPopover,
    GlSkeletonLoader,
    IssueDueDate,
    IssueMilestone,
    IssueWeight: () => import('ee_component/issues/components/issue_weight.vue'),
    StatusBadge,
    WorkItemTypeIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [timeagoMixin],
  props: {
    target: {
      type: HTMLAnchorElement,
      required: true,
    },
    namespacePath: {
      type: String,
      required: true,
    },
    iid: {
      type: String,
      required: true,
    },
    cachedTitle: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      issue: {},
    };
  },
  computed: {
    formattedTime() {
      return this.timeFormatted(this.issue.createdAt);
    },
    title() {
      return this.issue?.title || this.cachedTitle;
    },
    showDetails() {
      return Object.keys(this.issue).length > 0;
    },
    isIssueClosed() {
      return this.issue?.state === STATUS_CLOSED;
    },
  },
  apollo: {
    issue: {
      query,
      update: (data) => data.project?.issue || {},
      variables() {
        const { namespacePath, iid } = this;

        return {
          projectPath: namespacePath,
          iid,
        };
      },
    },
  },
};
</script>

<template>
  <gl-popover :target="target" boundary="viewport" placement="top" show>
    <gl-skeleton-loader v-if="$apollo.queries.issue.loading" :height="15">
      <rect width="250" height="15" rx="4" />
    </gl-skeleton-loader>
    <div v-else-if="showDetails" class="gl-flex gl-items-center gl-gap-2">
      <status-badge :issuable-type="$options.TYPE_ISSUE" :state="issue.state" />
      <gl-icon
        v-if="issue.confidential"
        v-gl-tooltip
        name="eye-slash"
        :title="__('Confidential')"
        :aria-label="__('Confidential')"
        variant="warning"
      />
      <span class="gl-text-subtle">
        {{ __('Opened') }} <time :datetime="issue.createdAt">{{ formattedTime }}</time>
      </span>
    </div>
    <h5 v-if="!$apollo.queries.issue.loading" class="gl-my-3">{{ title }}</h5>
    <!-- eslint-disable @gitlab/vue-require-i18n-strings -->
    <div>
      <work-item-type-icon v-if="!$apollo.queries.issue.loading" :work-item-type="issue.type" />
      <span class="gl-text-subtle">{{ `${namespacePath}#${iid}` }}</span>
    </div>
    <!-- eslint-enable @gitlab/vue-require-i18n-strings -->

    <div v-if="!$apollo.queries.issue.loading" class="gl-mt-2 gl-flex gl-text-subtle">
      <issue-due-date
        v-if="issue.dueDate"
        :date="issue.dueDate.toString()"
        :closed="isIssueClosed"
        tooltip-placement="top"
        class="gl-mr-4"
        css-class="gl-flex gl-whitespace-nowrap"
      />
      <issue-weight v-if="issue.weight" :weight="issue.weight" class="gl-mr-4 gl-flex" />
      <issue-milestone
        v-if="issue.milestone"
        :milestone="issue.milestone"
        class="gl-flex gl-overflow-hidden"
      />
    </div>
  </gl-popover>
</template>
