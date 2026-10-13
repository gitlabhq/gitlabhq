<script>
import { GlIcon } from '@gitlab/ui';
import { getDueDateStatus, humanTimeframe, newDate } from '~/lib/utils/datetime_utility';
import { __ } from '~/locale';
import WorkItemAttribute from '~/vue_shared/components/work_item_attribute.vue';

export default {
  name: 'WorkItemDatesAttribute',
  components: {
    GlIcon,
    WorkItemAttribute,
  },
  props: {
    startDate: {
      type: String,
      required: false,
      default: null,
    },
    dueDate: {
      type: String,
      required: false,
      default: null,
    },
    isClosed: {
      type: Boolean,
      required: false,
      default: false,
    },
    anchorId: {
      type: String,
      required: false,
      default: 'issuable-due-date',
    },
    iconSize: {
      type: Number,
      required: false,
      default: 16,
    },
    tooltipPlacement: {
      type: String,
      required: false,
      default: 'top',
    },
    wrapperComponent: {
      type: String,
      required: false,
      default: 'button',
    },
    wrapperComponentClass: {
      type: String,
      required: false,
      default: 'gl-text-subtle gl-bg-transparent gl-border-0 gl-p-0 focus-visible:gl-focus-inset',
    },
  },
  computed: {
    datesText() {
      if (this.startDate || this.dueDate) {
        return humanTimeframe(newDate(this.startDate), newDate(this.dueDate));
      }

      return null;
    },
    dueDateStatus() {
      return getDueDateStatus(this.dueDate, !this.isClosed);
    },
    datesLabel() {
      if (this.startDate && this.dueDate) {
        return __('Dates');
      }
      return this.startDate ? __('Start date') : __('Due date');
    },
    datesTooltipTitle() {
      const { statusLabel } = this.dueDateStatus;
      return statusLabel ? `${this.datesLabel} (${statusLabel})` : this.datesLabel;
    },
  },
};
</script>

<template>
  <work-item-attribute
    v-if="datesText"
    :anchor-id="anchorId"
    :wrapper-component="wrapperComponent"
    :wrapper-component-class="wrapperComponentClass"
    :title="datesText"
    :tooltip-text="datesTooltipTitle"
    :tooltip-placement="tooltipPlacement"
    :sr-only-text="datesTooltipTitle"
  >
    <template #icon>
      <gl-icon
        :variant="dueDateStatus.iconVariant"
        :name="dueDateStatus.iconName"
        :size="iconSize"
        class="gl-shrink-0"
      />
    </template>
  </work-item-attribute>
</template>
