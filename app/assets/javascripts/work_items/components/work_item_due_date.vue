<script>
import { GlDatepicker, GlFormGroup } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import { formatDate, newDate, toISODateFormat } from '~/lib/utils/datetime_utility';
import {
  I18N_WORK_ITEM_ERROR_UPDATING,
  sprintfWorkItem,
  TRACKING_CATEGORY_SHOW,
  WIDGET_TYPE_START_AND_DUE_DATE,
} from '~/work_items/constants';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import WorkItemSidebarWidget from './shared/work_item_sidebar_widget.vue';

const nullObjectDate = new Date(0);

export default {
  dueDateInputId: 'due-date-input',
  startDateInputId: 'start-date-input',
  components: {
    GlDatepicker,
    GlFormGroup,
    WorkItemSidebarWidget,
  },
  mixins: [Tracking.mixin()],
  props: {
    canUpdate: {
      type: Boolean,
      required: false,
      default: false,
    },
    dueDate: {
      type: String,
      required: false,
      default: null,
    },
    startDate: {
      type: String,
      required: false,
      default: null,
    },
    workItemType: {
      type: String,
      required: true,
    },
    workItem: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      dirtyDueDate: null,
      dirtyStartDate: null,
      isUpdating: false,
    };
  },
  computed: {
    workItemId() {
      return this.workItem.id;
    },
    datesUnchanged() {
      const dirtyDueDate = this.dirtyDueDate || nullObjectDate;
      const dirtyStartDate = this.dirtyStartDate || nullObjectDate;
      const dueDate = this.dueDate ? newDate(this.dueDate) : nullObjectDate;
      const startDate = this.startDate ? newDate(this.startDate) : nullObjectDate;
      return (
        dirtyDueDate.getTime() === dueDate.getTime() &&
        dirtyStartDate.getTime() === startDate.getTime()
      );
    },
    isDatepickerDisabled() {
      return !this.canUpdate || this.isUpdating;
    },
    isWithOnlyDueDate() {
      return Boolean(this.dueDate && !this.startDate);
    },
    isWithOnlyStartDate() {
      return Boolean(!this.dueDate && this.startDate);
    },
    isWithNoDates() {
      return !this.dueDate && !this.startDate;
    },
    tracking() {
      return {
        category: TRACKING_CATEGORY_SHOW,
        label: 'item_dates',
        property: `type_${this.workItemType}`,
      };
    },
    startDateValue() {
      return this.startDate
        ? formatDate(this.startDate, 'mmm d, yyyy', true)
        : s__('WorkItem|None');
    },
    dueDateValue() {
      return this.dueDate ? formatDate(this.dueDate, 'mmm d, yyyy', true) : s__('WorkItem|None');
    },
    optimisticResponse() {
      const workItemDatesWidget = this.workItem.widgets.find(
        (widget) => widget.type === WIDGET_TYPE_START_AND_DUE_DATE,
      );

      return {
        workItemUpdate: {
          errors: [],
          workItem: {
            ...this.workItem,
            widgets: [
              ...this.workItem.widgets.filter(
                (widget) => widget.type !== WIDGET_TYPE_START_AND_DUE_DATE,
              ),
              {
                ...workItemDatesWidget,
                dueDate: this.dirtyDueDate ? toISODateFormat(this.dirtyDueDate) : null,
                startDate: this.dirtyStartDate ? toISODateFormat(this.dirtyStartDate) : null,
              },
            ],
          },
        },
      };
    },
  },
  watch: {
    dueDate: {
      handler(newDueDate) {
        this.dirtyDueDate = newDate(newDueDate);
      },
      immediate: true,
    },
    startDate: {
      handler(newStartDate) {
        this.dirtyStartDate = newDate(newStartDate);
      },
      immediate: true,
    },
  },
  methods: {
    clearDueDatePicker() {
      this.dirtyDueDate = null;
    },
    clearStartDatePicker() {
      this.dirtyStartDate = null;
    },
    handleStartDateInput() {
      if (this.dirtyDueDate && this.dirtyStartDate > this.dirtyDueDate) {
        this.dirtyDueDate = this.dirtyStartDate;
      }
    },
    updateDates() {
      if (this.datesUnchanged) {
        return;
      }

      this.track('updated_dates');

      this.isUpdating = true;

      this.$apollo
        .mutate({
          mutation: updateWorkItemMutation,
          variables: {
            input: {
              id: this.workItemId,
              startAndDueDateWidget: {
                dueDate: this.dirtyDueDate ? toISODateFormat(this.dirtyDueDate) : null,
                startDate: this.dirtyStartDate ? toISODateFormat(this.dirtyStartDate) : null,
              },
            },
          },
          optimisticResponse: this.optimisticResponse,
        })
        .then(({ data }) => {
          if (data.workItemUpdate.errors.length) {
            throw new Error(data.workItemUpdate.errors.join('; '));
          }
        })
        .catch((error) => {
          const message = sprintfWorkItem(I18N_WORK_ITEM_ERROR_UPDATING, this.workItemType);
          this.$emit('error', message);
          Sentry.captureException(error);
        })
        .finally(() => {
          this.isUpdating = false;
        });
    },
  },
};
</script>

<template>
  <work-item-sidebar-widget
    :can-update="canUpdate"
    :is-updating="isUpdating"
    data-testid="work-item-start-due-dates"
    @stopEditing="updateDates"
  >
    <template #title>
      {{ s__('WorkItem|Dates') }}
    </template>
    <template #content>
      <p class="gl-m-0 gl-pb-1">
        <span class="gl-inline-block gl-min-w-8">{{ s__('WorkItem|Start') }}:</span>
        <span data-testid="start-date-value" :class="{ 'gl-text-subtle': !startDate }">
          {{ startDateValue }}
        </span>
      </p>
      <p class="gl-m-0 gl-pt-1">
        <span class="gl-inline-block gl-min-w-8">{{ s__('WorkItem|Due') }}:</span>
        <span data-testid="due-date-value" :class="{ 'gl-text-subtle': !dueDate }">
          {{ dueDateValue }}
        </span>
      </p>
    </template>
    <template #editing-content="{ stopEditing }">
      <gl-form-group
        class="gl-m-0 gl-flex gl-items-center gl-gap-3"
        :label="s__('WorkItem|Start')"
        :label-for="$options.startDateInputId"
        label-class="!gl-font-normal !gl-pb-0 gl-min-w-7 sm:gl-min-w-fit md:gl-min-w-7 gl-break-words"
      >
        <gl-datepicker
          v-model="dirtyStartDate"
          container="body"
          :disabled="isDatepickerDisabled"
          :input-id="$options.startDateInputId"
          :target="null"
          show-clear-button
          class="work-item-date-picker gl-max-w-20"
          data-testid="start-date-picker"
          @clear="clearStartDatePicker"
          @close="handleStartDateInput"
          @keydown.esc.native="stopEditing"
        />
      </gl-form-group>
      <gl-form-group
        class="gl-m-0 gl-flex gl-items-center gl-gap-3"
        :label="s__('WorkItem|Due')"
        :label-for="$options.dueDateInputId"
        label-class="!gl-font-normal !gl-pb-0 gl-min-w-7 sm:gl-min-w-fit md:gl-min-w-7 gl-break-words"
      >
        <gl-datepicker
          v-model="dirtyDueDate"
          container="body"
          :disabled="isDatepickerDisabled"
          :input-id="$options.dueDateInputId"
          :min-date="dirtyStartDate"
          :target="null"
          show-clear-button
          class="work-item-date-picker gl-max-w-20"
          data-testid="due-date-picker"
          @clear="clearDueDatePicker"
          @keydown.esc.native="stopEditing"
        />
      </gl-form-group>
    </template>
  </work-item-sidebar-widget>
</template>
