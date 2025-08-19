<script>
import {
  GlIcon,
  GlPopover,
  GlSkeletonLoader,
  GlTooltipDirective,
  GlAvatarsInline,
} from '@gitlab/ui';
import { n__ } from '~/locale';
import query from 'ee_else_ce/issuable/popover/queries/issue.query.graphql';
import IssueDueDate from '~/boards/components/issue_due_date.vue';
import IssueMilestone from '~/issuable/components/issue_milestone.vue';
import StatusBadge from '~/issuable/components/status_badge.vue';
import { STATUS_CLOSED as ISSUABLE_STATUS_CLOSED } from '~/issues/constants';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import WorkItemTypeIcon from '~/work_items/components/work_item_type_icon.vue';
import {
  findMilestoneWidget,
  findStartAndDueDateWidget,
  findAssigneesWidget,
  findWeightWidget,
  findStatusWidget,
} from '~/work_items/utils';
import {
  STATE_CLOSED as WORK_ITEM_STATUS_CLOSED,
  WORK_ITEM_TYPE_NAME_EPIC,
} from '~/work_items/constants';

export default {
  name: 'IssuePopover',
  components: {
    GlIcon,
    GlPopover,
    GlSkeletonLoader,
    GlAvatarsInline,
    IssueDueDate,
    IssueMilestone,
    IssueWeight: () => import('ee_component/issues/components/issue_weight.vue'),
    IssueStatus: () =>
      import('ee_component/work_items/components/shared/work_item_status_badge.vue'),
    StatusBadge,
    WorkItemTypeIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [timeagoMixin],
  props: {
    target: {
      type: [HTMLElement, Function, Object, String],
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
      required: false,
      default: '',
    },
    show: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      shouldFetch: false,
      workItem: null,
    };
  },
  apollo: {
    workItem: {
      query,
      variables() {
        return {
          fullPath: this.namespacePath,
          iid: this.iid,
        };
      },
      update: (data) => data.namespace?.workItem,
      skip() {
        return !this.shouldFetch;
      },
    },
  },
  computed: {
    formattedTime() {
      const { createdAt } = this.workItem;
      return createdAt ? this.timeFormatted(createdAt) : '';
    },
    isIssueClosed() {
      return (
        this.workItem?.state &&
        [ISSUABLE_STATUS_CLOSED, WORK_ITEM_STATUS_CLOSED].includes(this.workItem.state)
      );
    },
    reference() {
      return this.type === WORK_ITEM_TYPE_NAME_EPIC
        ? this.workItem.fullReference?.replaceAll('#', '&')
        : this.workItem.fullReference;
    },
    workItemType() {
      return this.workItem?.workItemType || {};
    },
    workItemTypeName() {
      return this.workItemType?.name || '';
    },
    workItemTypeIcon() {
      return this.workItemType?.iconName || '';
    },
    assignees() {
      const assigneesWidget = findAssigneesWidget(this.workItem);
      return assigneesWidget?.assignees?.nodes || [];
    },
    assigneeAvatars() {
      return this.assignees.map((assignee) => ({
        src: assignee.avatarUrl,
        alt: assignee.name,
      }));
    },
    moreAssigneesTooltip() {
      if (this.assignees.length > 2) {
        return n__('%d more assignee', '%d more assignees', this.assignees.length - 2);
      }
      return '';
    },
    datesWidget() {
      return findStartAndDueDateWidget(this.workItem) ?? {};
    },
    milestoneWidget() {
      return findMilestoneWidget(this.workItem) ?? {};
    },
    weightWidget() {
      return findWeightWidget(this.workItem) ?? {};
    },
    statusWidget() {
      return findStatusWidget(this.workItem) ?? {};
    },
  },
};
</script>

<template>
  <gl-popover
    :target="target"
    boundary="viewport"
    placement="top"
    :show="show"
    @show="shouldFetch = true"
  >
    <gl-skeleton-loader v-if="$apollo.queries.workItem.loading" :width="150" />
    <template v-else-if="workItem">
      <div class="gl-flex gl-items-center gl-gap-2">
        <status-badge v-if="isIssueClosed || !statusWidget.status" :state="workItem.state" />
        <gl-icon
          v-if="workItem.confidential"
          v-gl-tooltip
          name="eye-slash"
          :title="__('Confidential')"
          variant="warning"
          :aria-label="__('Confidential')"
        />
        <span class="gl-text-subtle">
          {{ __('Opened') }} <time :datetime="workItem.createdAt">{{ formattedTime }}</time>
        </span>
      </div>
      <div class="gl-heading-5 gl-my-3" data-testid="popover-title">{{ workItem.title }}</div>
      <div>
        <work-item-type-icon
          :work-item-type="workItemTypeName"
          :type-icon-name="workItemTypeIcon"
        />
        <span class="gl-text-subtle">{{ reference }}</span>
      </div>
      <div class="gl-mt-3 gl-flex gl-flex-wrap gl-items-center gl-gap-3 gl-text-subtle">
        <issue-due-date
          v-if="datesWidget.dueDate"
          :closed="isIssueClosed"
          css-class="gl-inline-flex"
          :date="datesWidget.dueDate"
          :start-date="datesWidget.startDate"
          tooltip-placement="top"
          class="gl-flex gl-items-center"
        />
        <issue-weight v-if="weightWidget.weight" :weight="weightWidget.weight" />
        <issue-milestone v-if="milestoneWidget.milestone" :milestone="milestoneWidget.milestone" />
        <div
          v-if="statusWidget.status || assignees.length"
          class="gl-flex gl-grow gl-items-center gl-justify-end gl-gap-3"
        >
          <gl-avatars-inline
            v-if="assignees.length"
            :avatars="assigneeAvatars"
            :avatar-size="16"
            :max-visible="2"
            :badge-sr-only-text="moreAssigneesTooltip"
            collapsed
            class="gl-flex gl-items-center"
          />
          <issue-status v-if="statusWidget.status" :item="statusWidget.status" />
        </div>
      </div>
    </template>
    <template v-else>
      <div class="gl-heading-5 gl-my-3" data-testid="popover-title">{{ cachedTitle }}</div>
    </template>
  </gl-popover>
</template>

<style>
/*
 * We need to override margins on popover body elements to ensure
 * that `gl-gap-3` works without any added spacing
 */
.gl-popover .popover-body .board-card-info {
  margin-right: 0;
}

/*
 * Adds spacing between calender icon and text
 */
.gl-popover .popover-body .board-card-info time {
  margin-left: 0.25rem;
}
</style>
