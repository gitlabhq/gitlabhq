<script>
import { GlButton, GlDatepicker, GlFormGroup, GlOutsideDirective as Outside } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import { formatDate, newDate, toISODateFormat } from '~/lib/utils/datetime_utility';
import { Mousetrap } from '~/lib/mousetrap';
import { keysFor, SIDEBAR_CLOSE_WIDGET } from '~/behaviors/shortcuts/keybindings';
import {
  I18N_WORK_ITEM_ERROR_UPDATING,
  sprintfWorkItem,
  TRACKING_CATEGORY_SHOW,
  WIDGET_TYPE_START_AND_DUE_DATE,
} from '~/work_items/constants';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';

const nullObjectDate = new Date(0);

export default {
  i18n: {
    dates: s__('WorkItem|Dates'),
    dueDate: s__('WorkItem|Due'),
    none: s__('WorkItem|None'),
    startDate: s__('WorkItem|Start'),
  },
  dueDateInputId: 'due-date-input',
  startDateInputId: 'start-date-input',
  components: {
    GlButton,
    GlDatepicker,
    GlFormGroup,
  },
  directives: {
    Outside,
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
      isEditing: false,
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
        : this.$options.i18n.none;
    },
    dueDateValue() {
      return this.dueDate ? formatDate(this.dueDate, 'mmm d, yyyy', true) : this.$options.i18n.none;
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
  mounted() {
    Mousetrap.bind(keysFor(SIDEBAR_CLOSE_WIDGET), this.collapseWidget);
  },
  beforeDestroy() {
    Mousetrap.unbind(keysFor(SIDEBAR_CLOSE_WIDGET));
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
    expandWidget() {
      this.isEditing = true;
    },
    collapseWidget(event = {}) {
      // This prevents outside directive from treating
      // a click on a select element within datepicker as an outside click,
      // therefore allowing user to select a month and a year without
      // triggering the mutation and immediately closing the dropdown
      if (event.target?.classList.contains('pika-select', 'pika-select-month', 'pika-select-year'))
        return;
      this.isEditing = false;
      this.updateDates();
    },
  },
};
</script>

<template>
  <section data-testid="work-item-start-due-dates">
    <div class="gl-flex gl-items-center gl-gap-3">
      <h3 :class="{ 'gl-sr-only': isEditing }" class="gl-heading-5 !gl-mb-0">
        {{ $options.i18n.dates }}
      </h3>
      <gl-button
        v-if="canUpdate && !isEditing"
        data-testid="edit-button"
        category="tertiary"
        size="small"
        class="gl-ml-auto"
        :disabled="isUpdating"
        @click="expandWidget"
        >{{ __('Edit') }}</gl-button
      >
    </div>
    <fieldset v-if="isEditing" data-testid="datepicker-wrapper">
      <div class="gl-flex gl-items-center gl-justify-between">
        <legend class="gl-mb-0 gl-border-b-0 gl-text-base gl-font-bold">
          {{ $options.i18n.dates }}
        </legend>
        <gl-button
          data-testid="apply-button"
          category="tertiary"
          size="small"
          :disabled="isUpdating"
          @click="collapseWidget"
          >{{ __('Apply') }}</gl-button
        >
      </div>
      <div
        v-outside="collapseWidget"
        class="gl-flex gl-flex-col gl-flex-wrap gl-gap-x-5 gl-gap-y-3 gl-pt-2 sm:gl-flex-row md:gl-flex-col"
      >
        <gl-form-group
          class="gl-m-0 gl-flex gl-items-center gl-gap-3"
          :label="$options.i18n.startDate"
          :label-for="$options.startDateInputId"
          label-class="!gl-font-normal !gl-pb-0 gl-min-w-7 sm:gl-min-w-fit md:gl-min-w-7 gl-break-words"
        >
          <gl-datepicker
            ref="startDatePicker"
            v-model="dirtyStartDate"
            container="body"
            :disabled="isDatepickerDisabled"
            :input-id="$options.startDateInputId"
            :target="null"
            show-clear-button
            class="work-item-date-picker gl-max-w-20"
            @clear="clearStartDatePicker"
            @close="handleStartDateInput"
            @keydown.esc.native="collapseWidget"
          />
        </gl-form-group>
        <gl-form-group
          class="gl-m-0 gl-flex gl-items-center gl-gap-3"
          :label="$options.i18n.dueDate"
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
            @keydown.esc.native="collapseWidget"
          />
        </gl-form-group>
      </div>
    </fieldset>
    <template v-else>
      <p class="gl-m-0 gl-pb-1">
        <span class="gl-inline-block gl-min-w-8">{{ $options.i18n.startDate }}:</span>
        <span data-testid="start-date-value" :class="{ 'gl-text-subtle': !startDate }">
          {{ startDateValue }}
        </span>
      </p>
      <p class="gl-m-0 gl-pt-1">
        <span class="gl-inline-block gl-min-w-8">{{ $options.i18n.dueDate }}:</span>
        <span data-testid="due-date-value" :class="{ 'gl-text-subtle': !dueDate }">
          {{ dueDateValue }}
        </span>
      </p>
    </template>
  </section>
</template>
