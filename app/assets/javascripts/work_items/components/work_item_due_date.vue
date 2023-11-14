<script>
import { GlButton, GlDatepicker, GlFormGroup } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { getDateWithUTC, newDateAsLocaleTime } from '~/lib/utils/datetime/date_calculation_utility';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import {
  I18N_WORK_ITEM_ERROR_UPDATING,
  sprintfWorkItem,
  TRACKING_CATEGORY_SHOW,
} from '~/work_items/constants';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';

const nullObjectDate = new Date(0);

export default {
  i18n: {
    addDueDate: s__('WorkItem|Add due date'),
    addStartDate: s__('WorkItem|Add start date'),
    dates: s__('WorkItem|Dates'),
    dueDate: s__('WorkItem|Due date'),
    none: s__('WorkItem|None'),
    startDate: s__('WorkItem|Start date'),
  },
  dueDateInputId: 'due-date-input',
  startDateInputId: 'start-date-input',
  components: {
    GlButton,
    GlDatepicker,
    GlFormGroup,
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
    workItemId: {
      type: String,
      required: true,
    },
    workItemType: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      dirtyDueDate: null,
      dirtyStartDate: null,
      isUpdating: false,
      showDueDateInput: false,
      showStartDateInput: false,
    };
  },
  computed: {
    datesUnchanged() {
      const dirtyDueDate = this.dirtyDueDate || nullObjectDate;
      const dirtyStartDate = this.dirtyStartDate || nullObjectDate;
      const dueDate = this.dueDate ? newDateAsLocaleTime(this.dueDate) : nullObjectDate;
      const startDate = this.startDate ? newDateAsLocaleTime(this.startDate) : nullObjectDate;
      return (
        dirtyDueDate.getTime() === dueDate.getTime() &&
        dirtyStartDate.getTime() === startDate.getTime()
      );
    },
    isDatepickerDisabled() {
      return !this.canUpdate || this.isUpdating;
    },
    isReadonlyWithOnlyDueDate() {
      return !this.canUpdate && this.dueDate && !this.startDate;
    },
    isReadonlyWithOnlyStartDate() {
      return !this.canUpdate && !this.dueDate && this.startDate;
    },
    isReadonlyWithNoDates() {
      return !this.canUpdate && !this.dueDate && !this.startDate;
    },
    labelClass() {
      return {
        'work-item-field-label': true,
        'gl-align-self-center gl-pb-0!': this.isReadonlyWithNoDates,
        'gl-mt-3 gl-pb-0!': !this.isReadonlyWithNoDates,
      };
    },
    showDueDateButton() {
      return this.canUpdate && !this.showDueDateInput;
    },
    showStartDateButton() {
      return this.canUpdate && !this.showStartDateInput;
    },
    tracking() {
      return {
        category: TRACKING_CATEGORY_SHOW,
        label: 'item_dates',
        property: `type_${this.workItemType}`,
      };
    },
  },
  watch: {
    dueDate: {
      handler(newDueDate) {
        this.dirtyDueDate = newDateAsLocaleTime(newDueDate);
        this.showDueDateInput = Boolean(newDueDate);
      },
      immediate: true,
    },
    startDate: {
      handler(newStartDate) {
        this.dirtyStartDate = newDateAsLocaleTime(newStartDate);
        this.showStartDateInput = Boolean(newStartDate);
      },
      immediate: true,
    },
  },
  methods: {
    clearDueDatePicker() {
      this.dirtyDueDate = null;
      this.showDueDateInput = false;
      this.updateDates();
    },
    clearStartDatePicker() {
      this.dirtyStartDate = null;
      this.showStartDateInput = false;
      this.updateDates();
    },
    async clickShowDueDate() {
      this.showDueDateInput = true;
      await this.$nextTick();
      this.$refs.dueDatePicker.show();
    },
    async clickShowStartDate() {
      this.showStartDateInput = true;
      await this.$nextTick();
      this.$refs.startDatePicker.show();
    },
    handleStartDateInput() {
      if (this.dirtyDueDate && this.dirtyStartDate > this.dirtyDueDate) {
        this.dirtyDueDate = this.dirtyStartDate;
        this.clickShowDueDate();
        return;
      }

      this.updateDates();
    },
    updateDates() {
      if (!this.canUpdate || this.datesUnchanged) {
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
                dueDate: getDateWithUTC(this.dirtyDueDate),
                startDate: getDateWithUTC(this.dirtyStartDate),
              },
            },
          },
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
  <gl-form-group
    class="work-item-due-date"
    :label="$options.i18n.dates"
    :label-class="labelClass"
    label-cols="3"
    label-cols-lg="2"
  >
    <span v-if="isReadonlyWithNoDates" class="gl-text-secondary gl-ml-4">
      {{ $options.i18n.none }}
    </span>
    <div v-else class="gl-display-flex gl-flex-wrap gl-gap-5">
      <gl-form-group
        class="gl-display-flex gl-align-items-center gl-m-0"
        :class="{ 'gl-ml-n3': isReadonlyWithOnlyDueDate }"
        :label="$options.i18n.startDate"
        :label-for="$options.startDateInputId"
        :label-sr-only="!showStartDateInput"
        label-class="gl-flex-shrink-0 gl-text-secondary gl-font-weight-normal! gl-pb-0! gl-ml-4 gl-mr-3"
      >
        <gl-datepicker
          v-if="showStartDateInput"
          ref="startDatePicker"
          v-model="dirtyStartDate"
          container="body"
          :disabled="isDatepickerDisabled"
          :input-id="$options.startDateInputId"
          show-clear-button
          :target="null"
          @clear="clearStartDatePicker"
          @close="handleStartDateInput"
        />
        <gl-button
          v-if="showStartDateButton"
          category="tertiary"
          class="gl-text-gray-500!"
          @click="clickShowStartDate"
        >
          {{ $options.i18n.addStartDate }}
        </gl-button>
      </gl-form-group>
      <gl-form-group
        v-if="!isReadonlyWithOnlyStartDate"
        class="gl-display-flex gl-align-items-center gl-m-0"
        :class="{ 'gl-ml-n3': isReadonlyWithOnlyDueDate }"
        :label="$options.i18n.dueDate"
        :label-for="$options.dueDateInputId"
        :label-sr-only="!showDueDateInput"
        label-class="gl-flex-shrink-0 gl-text-secondary gl-font-weight-normal! gl-pb-0! gl-ml-4 gl-mr-3"
      >
        <gl-datepicker
          v-if="showDueDateInput"
          ref="dueDatePicker"
          v-model="dirtyDueDate"
          container="body"
          :disabled="isDatepickerDisabled"
          :input-id="$options.dueDateInputId"
          :min-date="dirtyStartDate"
          show-clear-button
          :target="null"
          @clear="clearDueDatePicker"
          @close="updateDates"
        />
        <gl-button
          v-if="showDueDateButton"
          category="tertiary"
          class="gl-text-gray-500!"
          @click="clickShowDueDate"
        >
          {{ $options.i18n.addDueDate }}
        </gl-button>
      </gl-form-group>
    </div>
  </gl-form-group>
</template>
