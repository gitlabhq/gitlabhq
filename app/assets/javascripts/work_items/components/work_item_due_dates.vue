<script>
import {
  GlButton,
  GlDatepicker,
  GlFormGroup,
  GlOutsideDirective as Outside,
  GlFormRadio,
} from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { newWorkItemId, findStartAndDueDateWidget } from '~/work_items/utils';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import { Mousetrap } from '~/lib/mousetrap';
import { keysFor, SIDEBAR_CLOSE_WIDGET } from '~/behaviors/shortcuts/keybindings';
import { formatDate, newDate, toISODateFormat } from '~/lib/utils/datetime_utility';
import {
  I18N_WORK_ITEM_ERROR_UPDATING,
  sprintfWorkItem,
  TRACKING_CATEGORY_SHOW,
  WIDGET_TYPE_START_AND_DUE_DATE,
} from '~/work_items/constants';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import updateNewWorkItemMutation from '~/work_items/graphql/update_new_work_item.mutation.graphql';

const nullObjectDate = new Date(0);

const ROLLUP_TYPE_FIXED = 'fixed';
const ROLLUP_TYPE_INHERITED = 'inherited';

export default {
  i18n: {
    dates: s__('WorkItem|Dates'),
    dueDate: s__('WorkItem|Due'),
    none: s__('WorkItem|None'),
    startDate: s__('WorkItem|Start'),
    fixed: s__('WorkItem|Fixed'),
    inherited: s__('WorkItem|Inherited'),
  },
  dueDateInputId: 'due-date-input',
  startDateInputId: 'start-date-input',
  components: {
    GlButton,
    GlDatepicker,
    GlFormGroup,
    GlFormRadio,
  },
  directives: {
    Outside,
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
      dirtyDueDate: null,
      dirtyStartDate: null,
      isUpdating: false,
      isEditing: false,
      rollupType: null,
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
        : this.$options.i18n.none;
    },
    dueDateValue() {
      return this.dueDate ? formatDate(this.dueDate, 'mmm d, yyyy', true) : this.$options.i18n.none;
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
    isFixed: {
      handler(isFixed) {
        this.rollupType = isFixed ? ROLLUP_TYPE_FIXED : ROLLUP_TYPE_INHERITED;
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
                dueDate: this.dirtyDueDate ? toISODateFormat(this.dirtyDueDate) : null,
                startDate: this.dirtyStartDate ? toISODateFormat(this.dirtyStartDate) : null,
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
  <section data-testid="work-item-due-dates">
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
    <fieldset v-if="!isEditing && shouldRollUp" class="gl-mt-2 gl-flex gl-gap-5">
      <gl-form-radio
        v-model="rollupType"
        value="fixed"
        :disabled="!canUpdate || isUpdating"
        @change="updateRollupType"
      >
        {{ $options.i18n.fixed }}
      </gl-form-radio>
      <gl-form-radio
        v-model="rollupType"
        value="inherited"
        :disabled="!canUpdate || isUpdating"
        @change="updateRollupType"
      >
        {{ $options.i18n.inherited }}
      </gl-form-radio>
    </fieldset>
    <fieldset v-if="isEditing" data-testid="datepicker-wrapper">
      <div class="gl-flex gl-items-center gl-justify-between">
        <legend class="gl-mb-0 gl-border-b-0 gl-text-base gl-font-bold">
          {{ $options.i18n.dates }}
        </legend>
        <gl-button
          data-testid="apply-button"
          category="tertiary"
          size="small"
          class="gl-mr-2"
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
            show-clear-button
            :target="null"
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
            show-clear-button
            :target="null"
            class="work-item-date-picker gl-max-w-20"
            data-testid="due-date-picker"
            @clear="clearDueDatePicker"
            @keydown.esc.native="collapseWidget"
          />
        </gl-form-group>
      </div>
    </fieldset>
    <template v-else>
      <p class="gl-m-0 gl-py-1">
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
