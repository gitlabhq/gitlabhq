<script>
import { GlIcon, GlSkeletonLoader } from '@gitlab/ui';
import { STATUS_CLOSED } from '~/issues/constants';
import { humanTimeframe, isInPast, newDate } from '~/lib/utils/datetime_utility';
import { __ } from '~/locale';
import { STATE_CLOSED, METADATA_KEYS } from '~/work_items/constants';
import {
  findMilestoneWidget,
  findStartAndDueDateWidget,
  findTimeTrackingWidget,
} from '~/work_items/utils';
import IssuableMilestone from '~/vue_shared/issuable/list/components/issuable_milestone.vue';
import WorkItemAttribute from '~/vue_shared/components/work_item_attribute.vue';

export default {
  components: {
    IssuableMilestone,
    WorkItemAttribute,
    GlIcon,
    GlSkeletonLoader,
  },
  constants: {
    METADATA_KEYS,
  },
  props: {
    issue: {
      type: Object,
      required: true,
    },
    detailLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    hiddenMetadataKeys: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    milestone() {
      return this.issue.milestone || findMilestoneWidget(this.issue)?.milestone;
    },
    dueDate() {
      return this.issue.dueDate || findStartAndDueDateWidget(this.issue)?.dueDate;
    },
    datesText() {
      if (this.startDate || this.dueDate) {
        return humanTimeframe(newDate(this.startDate), newDate(this.dueDate));
      }

      return null;
    },
    isClosed() {
      return this.issue.state === STATUS_CLOSED || this.issue.state === STATE_CLOSED;
    },
    isOverdue() {
      if (!this.dueDate) {
        return false;
      }
      return isInPast(newDate(this.dueDate)) && !this.isClosed;
    },
    datesTooltipTitle() {
      return this.isOverdue ? `${__('Dates')} (${__('overdue')})` : __('Dates');
    },
    dateIcon() {
      return this.isOverdue ? 'calendar-overdue' : 'calendar';
    },
    startDate() {
      return findStartAndDueDateWidget(this.issue)?.startDate;
    },
    timeEstimate() {
      return (
        findTimeTrackingWidget(this.issue)?.humanReadableAttributes?.timeEstimate ||
        this.issue.humanTimeEstimate ||
        this.issue.timeStats?.humanTimeEstimate
      );
    },
  },
};
</script>

<template>
  <div class="gl-contents">
    <slot name="weight"></slot>
    <issuable-milestone
      v-if="milestone && !hiddenMetadataKeys.includes($options.constants.METADATA_KEYS.MILESTONE)"
      :milestone="milestone"
    />
    <span v-else-if="detailLoading">
      <gl-skeleton-loader :width="55" :lines="1" equal-width-lines />
    </span>
    <slot name="iteration"></slot>
    <work-item-attribute
      v-if="datesText && !hiddenMetadataKeys.includes($options.constants.METADATA_KEYS.DATES)"
      anchor-id="issuable-due-date"
      wrapper-component="button"
      wrapper-component-class="issuable-due-date gl-text-subtle gl-bg-transparent gl-border-0 gl-p-0 focus-visible:gl-focus-inset"
      :title="datesText"
      :tooltip-text="datesTooltipTitle"
      tooltip-placement="top"
    >
      <template #icon>
        <gl-icon
          :variant="isOverdue ? 'danger' : 'current'"
          :name="dateIcon"
          :size="12"
          class="gl-shrink-0"
        />
      </template>
    </work-item-attribute>
    <span v-else-if="detailLoading">
      <gl-skeleton-loader :width="30" :lines="1" equal-width-lines />
    </span>
    <work-item-attribute
      v-if="timeEstimate"
      anchor-id="time-estimate"
      wrapper-component="button"
      icon-name="timer"
      icon-size="12"
      :title="timeEstimate"
      wrapper-component-class="gl-text-subtle gl-bg-transparent gl-border-0 gl-p-0 focus-visible:gl-focus-inset"
      :tooltip-text="__('Estimate')"
      tooltip-placement="top"
    />
    <span v-else-if="detailLoading">
      <gl-skeleton-loader :width="25" :lines="1" equal-width-lines />
    </span>
    <slot></slot>
  </div>
</template>
