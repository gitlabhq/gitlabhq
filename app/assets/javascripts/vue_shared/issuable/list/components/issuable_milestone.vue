<script>
import { GlIcon } from '@gitlab/ui';
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
    GlIcon,
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
  <span>
    <work-item-attribute
      anchor-id="issuable-milestone"
      :title="milestone.title"
      wrapper-component-class="gl-text-sm !gl-text-subtle"
      :tooltip-text="milestoneDate"
      tooltip-placement="top"
      class="issuable-milestone gl-mr-3"
      is-link
      :href="milestoneLink"
    >
      <template #icon>
        <gl-icon name="milestone" :size="12" />
      </template>
    </work-item-attribute>
  </span>
</template>
