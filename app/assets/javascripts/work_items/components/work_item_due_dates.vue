<script>
import { GlDatepicker, GlFormGroup, GlFormRadio } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { findStartAndDueDateWidget, newWorkItemId } from '~/work_items/utils';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import { formatDate, newDate, toISODateFormat } from '~/lib/utils/datetime_utility';
import {
  I18N_WORK_ITEM_ERROR_UPDATING,
  sprintfWorkItem,
  TRACKING_CATEGORY_SHOW,
  WIDGET_TYPE_START_AND_DUE_DATE,
} from '../constants';
import updateWorkItemMutation from '../graphql/update_work_item.mutation.graphql';
import updateNewWorkItemMutation from '../graphql/update_new_work_item.mutation.graphql';
import WorkItemSidebarWidget from './shared/work_item_sidebar_widget.vue';

const nullObjectDate = new Date(0);

const ROLLUP_TYPE_FIXED = 'fixed';
const ROLLUP_TYPE_INHERITED = 'inherited';

export default {
  dueDateInputId: 'due-date-input',
  startDateInputId: 'start-date-input',
  components: {
    GlDatepicker,
    GlFormGroup,
    GlFormRadio,
    WorkItemSidebarWidget,
  },
  mixins: [Tracking.mixin()],
  props: {
    workItem: {
      type: Object,
      required: true,
    },
    fullPath: {
      type: String,
      required: true,
    },
    workItemType: {
      type: String,
      required: true,
    },
    canUpdate: {
      type: Boolean,
      required: false,
      default: false,
    },
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
    isFixed: {
      type: Boolean,
      required: false,
      default: false,
    },
    shouldRollUp: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      localDueDate: null,
      localStartDate: null,
      isUpdating: false,
      rollupType: null,
    };
  },
  computed: {
    workItemId() {
      return this.workItem.id;
    },
    datesUnchanged() {
      const localDueDate = this.localDueDate || nullObjectDate;
      const localStartDate = this.localStartDate || nullObjectDate;
      const dueDate = this.dueDate ? newDate(this.dueDate) : nullObjectDate;
      const startDate = this.startDate ? newDate(this.startDate) : nullObjectDate;
      return (
        localDueDate.getTime() === dueDate.getTime() &&
        localStartDate.getTime() === startDate.getTime()
      );
    },
    isDatepickerDisabled() {
      return !this.canUpdate || this.isUpdating;
    },
    // eslint-disable-next-line vue/no-unused-properties
    tracking() {
      return {
        category: TRACKING_CATEGORY_SHOW,
        label: 'item_rolledup_dates',
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
      const workItemDatesWidget = findStartAndDueDateWidget(this.workItem);

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
                dueDate: this.localDueDate ? toISODateFormat(this.localDueDate) : null,
                startDate: this.localStartDate ? toISODateFormat(this.localStartDate) : null,
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
        this.localDueDate = newDate(newDueDate);
      },
      immediate: true,
    },
    startDate: {
      handler(newStartDate) {
        this.localStartDate = newDate(newStartDate);
      },
      immediate: true,
    },
    isFixed: {
      handler(isFixed) {
        this.rollupType = isFixed ? ROLLUP_TYPE_FIXED : ROLLUP_TYPE_INHERITED;
      },
      immediate: true,
    },
  },
  methods: {
    clearDueDatePicker() {
      this.localDueDate = null;
    },
    clearStartDatePicker() {
      this.localStartDate = null;
    },
    handleStartDateInput() {
      if (this.localDueDate && this.localStartDate > this.localDueDate) {
        this.localDueDate = this.localStartDate;
      }
    },
    updateRollupType() {
      this.isUpdating = true;

      this.track('updated_rollup_type');

      if (this.workItemId === newWorkItemId(this.workItemType)) {
        this.$apollo.mutate({
          mutation: updateNewWorkItemMutation,
          variables: {
            input: {
              workItemType: this.workItemType,
              fullPath: this.fullPath,
              rolledUpDates: {
                isFixed: this.rollupType === ROLLUP_TYPE_FIXED,
                rollUp: this.shouldRollUp,
              },
            },
          },
        });

        this.isUpdating = false;
        return;
      }

      this.$apollo
        .mutate({
          mutation: updateWorkItemMutation,
          variables: {
            input: {
              id: this.workItemId,
              startAndDueDateWidget: {
                isFixed: this.rollupType === ROLLUP_TYPE_FIXED,
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
    updateDates() {
      if (this.datesUnchanged) {
        return;
      }

      this.track('updated_dates');

      this.isUpdating = true;
      this.rollupType = ROLLUP_TYPE_FIXED;

      if (this.workItemId === newWorkItemId(this.workItemType)) {
        this.$apollo.mutate({
          mutation: updateNewWorkItemMutation,
          variables: {
            input: {
              workItemType: this.workItemType,
              fullPath: this.fullPath,
              rolledUpDates: {
                isFixed: true,
                dueDate: this.localDueDate ? toISODateFormat(this.localDueDate) : null,
                startDate: this.localStartDate ? toISODateFormat(this.localStartDate) : null,
                rollUp: this.shouldRollUp,
              },
            },
          },
        });

        this.isUpdating = false;
        return;
      }

      this.$apollo
        .mutate({
          mutation: updateWorkItemMutation,
          variables: {
            input: {
              id: this.workItemId,
              startAndDueDateWidget: {
                isFixed: true,
                dueDate: this.localDueDate ? toISODateFormat(this.localDueDate) : null,
                startDate: this.localStartDate ? toISODateFormat(this.localStartDate) : null,
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
    data-testid="work-item-due-dates"
    @stopEditing="updateDates"
  >
    <template #title>
      {{ s__('WorkItem|Dates') }}
    </template>
    <template #content>
      <fieldset v-if="shouldRollUp" class="gl-mt-2 gl-flex gl-gap-5">
        <legend class="gl-sr-only">{{ s__('WorkItem|Dates') }}</legend>
        <gl-form-radio
          v-model="rollupType"
          value="fixed"
          :disabled="!canUpdate || isUpdating"
          @change="updateRollupType"
        >
          {{ s__('WorkItem|Fixed') }}
        </gl-form-radio>
        <gl-form-radio
          v-model="rollupType"
          value="inherited"
          :disabled="!canUpdate || isUpdating"
          @change="updateRollupType"
        >
          {{ s__('WorkItem|Inherited') }}
        </gl-form-radio>
      </fieldset>
      <p class="gl-m-0 gl-py-1">
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
          v-model="localStartDate"
          class="gl-max-w-20"
          container="body"
          :disabled="isDatepickerDisabled"
          :input-id="$options.startDateInputId"
          show-clear-button
          :target="null"
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
          v-model="localDueDate"
          class="gl-max-w-20"
          container="body"
          :disabled="isDatepickerDisabled"
          :input-id="$options.dueDateInputId"
          :min-date="localStartDate"
          show-clear-button
          :target="null"
          data-testid="due-date-picker"
          @clear="clearDueDatePicker"
          @keydown.esc.native="stopEditing"
        />
      </gl-form-group>
    </template>
  </work-item-sidebar-widget>
</template>
