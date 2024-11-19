<script>
import { GlFormInput } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import {
  DurationParseError,
  outputChronicDuration,
  parseChronicDuration,
} from '~/chronic_duration';
import { __ } from '~/locale';

export default {
  components: {
    GlFormInput,
  },
  model: {
    prop: 'value',
    event: 'change',
  },
  props: {
    value: {
      type: Number,
      required: false,
      default: null,
    },
    name: {
      type: String,
      required: false,
      default: null,
    },
    integerRequired: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  data() {
    return {
      numberData: this.value,
      humanReadableData: this.convertDuration(this.value),
      isValueValid: this.value === null ? null : true,
    };
  },
  computed: {
    numberValue: {
      get() {
        return this.numberData;
      },
      set(value) {
        if (this.numberData !== value) {
          this.numberData = value;
          this.humanReadableData = this.convertDuration(value);
          this.isValueValid = value === null ? null : true;
        }
        this.emitEvents();
      },
    },
    humanReadableValue: {
      get() {
        return this.humanReadableData;
      },
      set(value) {
        this.humanReadableData = value;
        try {
          if (value === '') {
            this.numberData = null;
            this.isValueValid = null;
          } else {
            this.numberData = parseChronicDuration(value, {
              keepZero: true,
              raiseExceptions: true,
            });
            this.isValueValid = true;
          }
        } catch (e) {
          if (e instanceof DurationParseError) {
            this.isValueValid = false;
          } else {
            Sentry.captureException(e);
          }
        }
        this.emitEvents(true);
      },
    },
    isValidDecimal() {
      return !this.integerRequired || this.numberData === null || Number.isInteger(this.numberData);
    },
    feedback() {
      if (this.isValueValid === false) {
        return this.$options.i18n.INVALID_INPUT_FEEDBACK;
      }
      if (!this.isValidDecimal) {
        return this.$options.i18n.INVALID_DECIMAL_FEEDBACK;
      }
      return '';
    },
  },
  i18n: {
    INVALID_INPUT_FEEDBACK: __('Please enter a valid time interval'),
    INVALID_DECIMAL_FEEDBACK: __('An integer value is required for seconds'),
  },
  watch: {
    value() {
      this.numberValue = this.value;
    },
  },
  mounted() {
    this.emitEvents();
  },
  methods: {
    convertDuration(value) {
      return value === null ? '' : outputChronicDuration(value);
    },
    emitEvents(emitChange = false) {
      if (emitChange && this.isValueValid !== false && this.isValidDecimal) {
        this.$emit('change', this.numberData);
      }
      const { feedback } = this;
      this.$refs.text.$el.setCustomValidity(feedback);
      this.$refs.hidden.setCustomValidity(feedback);
      this.$emit('valid', {
        valid: this.isValueValid && this.isValidDecimal,
        feedback,
      });
    },
  },
};
</script>
<template>
  <div>
    <gl-form-input ref="text" v-bind="$attrs" v-model="humanReadableValue" />
    <input ref="hidden" type="hidden" :name="name" :value="numberValue" />
  </div>
</template>
