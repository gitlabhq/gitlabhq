<script>
import { GlModal, GlForm, GlFormFields, GlFormDate } from '@gitlab/ui';
import { formValidators } from '@gitlab/ui/dist/utils';
import { s__, __ } from '~/locale';
import { isInPast, fallsBefore } from '~/lib/utils/datetime_utility';
import Tracking from '~/tracking';
import { INSTRUMENT_TODO_ITEM_CLICK } from '~/todos/constants';

const FORM_ID = 'custom-snooze-form';
const FORM_GROUPS_CLASSES = 'sm:gl-w-1/3';
const DEFAULT_TIME = '09:00';
const MODAL_ACTION_CLASSES = 'gl-w-full sm:gl-w-auto';

export default {
  components: {
    GlModal,
    GlForm,
    GlFormFields,
    GlFormDate,
  },
  mixins: [Tracking.mixin()],
  data() {
    return {
      fields: {
        date: {
          label: this.$options.i18n.snoozeUntil,
          groupAttrs: { 'data-testid': 'date-input', class: FORM_GROUPS_CLASSES },
          validators: [
            formValidators.required(this.$options.i18n.dateRequired),
            formValidators.factory(this.$options.i18n.dateInPast, (val) => {
              const [year, month, day] = val.split('-').map(Number);

              const date = new Date();
              date.setDate(day);
              date.setMonth(month - 1);
              date.setFullYear(year);

              return !isInPast(date);
            }),
          ],
        },
        time: {
          label: this.$options.i18n.at,
          groupAttrs: { 'data-testid': 'time-input', class: FORM_GROUPS_CLASSES },
          inputAttrs: { type: 'time' },
          validators: [formValidators.required(this.$options.i18n.timeRequired)],
        },
      },
      formValues: {
        time: DEFAULT_TIME,
        date: '',
      },
      isModalVisible: false,
    };
  },
  computed: {
    actionPrimary() {
      return {
        text: s__('Todos|Snooze'),
        attributes: {
          type: 'submit',
          variant: 'confirm',
          form: FORM_ID,
          class: MODAL_ACTION_CLASSES,
        },
      };
    },
    datetime() {
      if (!this.formValues?.time || !this.formValues?.date) {
        return null;
      }
      return new Date(`${this.formValues.date}T${this.formValues.time}`);
    },
    datetimeIsInPast() {
      if (this.datetime === null) {
        return false;
      }
      return fallsBefore(this.datetime, new Date());
    },
  },
  methods: {
    // eslint-disable-next-line vue/no-unused-properties -- show() is part of the component's public API.
    show() {
      this.isModalVisible = true;
    },
    hide() {
      this.isModalVisible = false;
    },
    onDateInputChanged(event, inputHandler, validator) {
      inputHandler(event);
      validator();
    },
    async handleSubmit() {
      if (this.datetimeIsInPast) {
        return;
      }
      this.$emit('submit', this.datetime);

      this.track(INSTRUMENT_TODO_ITEM_CLICK, {
        label: 'snooze_until_a_specific_date_and_time',
        extra: {
          snooze_until: this.datetime.toISOString(),
        },
      });

      this.hide();
    },
  },
  FORM_ID,
  i18n: {
    snooze: s__('Todos|Snooze'),
    snoozeUntil: s__('Todos|Snooze until'),
    at: s__('Todos|At'),
    dateRequired: s__('Todos|The date is required.'),
    dateInPast: s__("Todos|Snooze date can't be in the past."),
    timeRequired: s__('Todos|The time is required.'),
    datetimeInPastError: s__('Todos|The selected date and time cannot be in the past.'),
    snoozeError: s__('Todos|Failed to snooze todo. Try again later.'),
  },
  actionSecondary: {
    text: __('Cancel'),
    attributes: {
      variant: 'default',
      class: MODAL_ACTION_CLASSES,
    },
  },
};
</script>

<template>
  <gl-modal
    v-model="isModalVisible"
    modal-id="custom-snooze-todo-modal"
    :title="$options.i18n.snooze"
    :action-primary="actionPrimary"
    :action-secondary="$options.actionSecondary"
    @primary.prevent="$emit('primary')"
  >
    <gl-form :id="$options.FORM_ID" @submit.prevent>
      <gl-form-fields
        v-model="formValues"
        :fields="fields"
        :form-id="$options.FORM_ID"
        @submit="handleSubmit"
      >
        <template #input(date)="{ input, blur: validate }">
          <gl-form-date @change="onDateInputChanged($event, input, validate)" @blur="validate" />
        </template>
      </gl-form-fields>
    </gl-form>
    <div v-if="datetimeIsInPast" class="gl-text-danger" data-testid="datetime-in-past-error">
      {{ $options.i18n.datetimeInPastError }}
    </div>
  </gl-modal>
</template>
