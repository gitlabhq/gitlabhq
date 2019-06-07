<script>
import _ from 'underscore';

export default {
  props: {
    initialCronInterval: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      inputNameAttribute: 'schedule[cron]',
      cronInterval: this.initialCronInterval,
      cronIntervalPresets: {
        everyDay: '0 4 * * *',
        everyWeek: '0 4 * * 0',
        everyMonth: '0 4 1 * *',
      },
      cronSyntaxUrl: 'https://en.wikipedia.org/wiki/Cron',
      customInputEnabled: false,
    };
  },
  computed: {
    intervalIsPreset() {
      return _.contains(this.cronIntervalPresets, this.cronInterval);
    },
    // The text input is editable when there's a custom interval, or when it's
    // a preset interval and the user clicks the 'custom' radio button
    isEditable() {
      return Boolean(this.customInputEnabled || !this.intervalIsPreset);
    },
  },
  watch: {
    cronInterval() {
      // updates field validation state when model changes, as
      // glFieldError only updates on input.
      this.$nextTick(() => {
        gl.pipelineScheduleFieldErrors.updateFormValidityState();
      });
    },
  },
  created() {
    if (this.intervalIsPreset) {
      this.enableCustomInput = false;
    }
  },
  methods: {
    toggleCustomInput(shouldEnable) {
      this.customInputEnabled = shouldEnable;

      if (shouldEnable) {
        // We need to change the value so other radios don't remain selected
        // because the model (cronInterval) hasn't changed. The server trims it.
        this.cronInterval = `${this.cronInterval} `;
      }
    },
  },
};
</script>

<template>
  <div class="interval-pattern-form-group">
    <div class="cron-preset-radio-input">
      <input
        id="custom"
        :name="inputNameAttribute"
        :value="cronInterval"
        :checked="isEditable"
        class="label-bold"
        type="radio"
        @click="toggleCustomInput(true)"
      />

      <label for="custom"> {{ s__('PipelineSheduleIntervalPattern|Custom') }} </label>

      <span class="cron-syntax-link-wrap">
        (<a :href="cronSyntaxUrl" target="_blank"> {{ __('Cron syntax') }} </a>)
      </span>
    </div>

    <div class="cron-preset-radio-input">
      <input
        id="every-day"
        v-model="cronInterval"
        :name="inputNameAttribute"
        :value="cronIntervalPresets.everyDay"
        class="label-bold"
        type="radio"
        @click="toggleCustomInput(false)"
      />

      <label class="label-bold" for="every-day"> {{ __('Every day (at 4:00am)') }} </label>
    </div>

    <div class="cron-preset-radio-input">
      <input
        id="every-week"
        v-model="cronInterval"
        :name="inputNameAttribute"
        :value="cronIntervalPresets.everyWeek"
        class="label-bold"
        type="radio"
        @click="toggleCustomInput(false)"
      />

      <label class="label-bold" for="every-week">
        {{ __('Every week (Sundays at 4:00am)') }}
      </label>
    </div>

    <div class="cron-preset-radio-input">
      <input
        id="every-month"
        v-model="cronInterval"
        :name="inputNameAttribute"
        :value="cronIntervalPresets.everyMonth"
        class="label-bold"
        type="radio"
        @click="toggleCustomInput(false)"
      />

      <label class="label-bold" for="every-month">
        {{ __('Every month (on the 1st at 4:00am)') }}
      </label>
    </div>

    <div class="cron-interval-input-wrapper">
      <input
        id="schedule_cron"
        v-model="cronInterval"
        :placeholder="__('Define a custom pattern with cron syntax')"
        :name="inputNameAttribute"
        :disabled="!isEditable"
        class="form-control inline cron-interval-input"
        type="text"
        required="true"
      />
    </div>
  </div>
</template>
