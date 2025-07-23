<script>
import { GlIcon, GlPopover, GlSkeletonLoader, GlTooltipDirective } from '@gitlab/ui';
import query from 'ee_else_ce/issuable/popover/queries/issue.query.graphql';
import IssueDueDate from '~/boards/components/issue_due_date.vue';
import IssueMilestone from '~/issuable/components/issue_milestone.vue';
import StatusBadge from '~/issuable/components/status_badge.vue';
import { STATUS_CLOSED } from '~/issues/constants';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import WorkItemTypeIcon from '~/work_items/components/work_item_type_icon.vue';
import {
  findMilestoneWidget,
  findStartAndDueDateWidget,
  findWeightWidget,
} from '~/work_items/utils';
import { WORK_ITEM_TYPE_NAME_EPIC } from '~/work_items/constants';

export default {
  name: 'IssuePopover',
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
      return this.workItem.state === STATUS_CLOSED;
    },
    reference() {
      return this.type === WORK_ITEM_TYPE_NAME_EPIC
        ? this.workItem.fullReference?.replaceAll('#', '&')
        : this.workItem.fullReference;
    },
    type() {
      return this.workItem.workItemType?.name;
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
        <status-badge :state="workItem.state" />
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
        <work-item-type-icon :work-item-type="type" />
        <span class="gl-text-subtle">{{ reference }}</span>
      </div>
      <div class="gl-mt-2 gl-flex gl-text-subtle">
        <issue-due-date
          v-if="datesWidget.dueDate"
          :closed="isIssueClosed"
          css-class="gl-inline-flex"
          :date="datesWidget.dueDate"
          :start-date="datesWidget.startDate"
          tooltip-placement="top"
        />
        <issue-weight v-if="weightWidget.weight" :weight="weightWidget.weight" />
        <issue-milestone v-if="milestoneWidget.milestone" :milestone="milestoneWidget.milestone" />
      </div>
    </template>
    <template v-else>
      <div class="gl-heading-5 gl-my-3" data-testid="popover-title">{{ cachedTitle }}</div>
    </template>
  </gl-popover>
</template>
