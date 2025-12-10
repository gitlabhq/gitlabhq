<script>
import {
  getTimeRemainingInWords,
  isInFuture,
  isInPast,
  isToday,
  localeDateFormat,
  newDate,
} from '~/lib/utils/datetime_utility';
import { __ } from '~/locale';
import WorkItemAttribute from '~/vue_shared/components/work_item_attribute.vue';

export default {
  name: 'IssuableMilestone',
  components: {
    WorkItemAttribute,
  },
  props: {
    milestone: {
      type: Object,
      required: true,
    },
  },
  computed: {
    milestoneDate() {
      if (this.milestone.dueDate) {
        const { dueDate, startDate } = this.milestone;
        const date = localeDateFormat.asDate.format(newDate(dueDate));
        const remainingTime = this.milestoneRemainingTime(dueDate, startDate);

        return `${date} (${remainingTime})`;
      }

      return __('Milestone');
    },
    milestoneLink() {
      return this.milestone.webPath || this.milestone.webUrl;
    },
  },
  methods: {
    milestoneRemainingTime(dueDate, startDate) {
      const due = newDate(dueDate);
      const start = newDate(startDate);

      if (dueDate && isInPast(due)) {
        return __('past due');
      }
      if (dueDate && isToday(due)) {
        return __('today');
      }
      if (startDate && isInFuture(start)) {
        return __('upcoming');
      }
      if (dueDate) {
        return getTimeRemainingInWords(due);
      }

      return '';
    },
  },
};
</script>

<template>
  <work-item-attribute
    anchor-id="issuable-milestone"
    :title="milestone.title"
    wrapper-component="a"
    wrapper-component-class="!gl-text-subtle gl-bg-transparent gl-border-0 gl-p-0 focus-visible:gl-focus-inset gl-max-w-30 gl-min-w-0"
    :tooltip-text="milestoneDate"
    tooltip-placement="top"
    icon-name="milestone"
    icon-size="12"
    :is-link="true"
    :href="milestoneLink"
  />
</template>
