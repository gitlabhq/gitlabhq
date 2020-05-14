<script>
import { GlSprintf, GlLink } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import { getWeekdayNames } from '~/lib/utils/datetime_utility';

export default {
  components: {
    GlSprintf,
    GlLink,
  },
  props: {
    initialCronInterval: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      isEditingCustom: false,
      randomHour: this.generateRandomHour(),
      randomWeekDayIndex: this.generateRandomWeekDayIndex(),
      randomDay: this.generateRandomDay(),
      inputNameAttribute: 'schedule[cron]',
      cronInterval: this.initialCronInterval,
      cronSyntaxUrl: 'https://en.wikipedia.org/wiki/Cron',
    };
  },
  computed: {
    cronIntervalPresets() {
      return {
        everyDay: `0 ${this.randomHour} * * *`,
        everyWeek: `0 ${this.randomHour} * * ${this.randomWeekDayIndex}`,
        everyMonth: `0 ${this.randomHour} ${this.randomDay} * *`,
      };
    },
    intervalIsPreset() {
      return Object.values(this.cronIntervalPresets).includes(this.cronInterval);
    },
    formattedTime() {
      if (this.randomHour > 12) {
        return `${this.randomHour - 12}:00pm`;
      } else if (this.randomHour === 12) {
        return `12:00pm`;
      }
      return `${this.randomHour}:00am`;
    },
    weekday() {
      return getWeekdayNames()[this.randomWeekDayIndex];
    },
    everyDayText() {
      return sprintf(s__(`Every day (at %{time})`), { time: this.formattedTime });
    },
    everyWeekText() {
      return sprintf(s__('Every week (%{weekday} at %{time})'), {
        weekday: this.weekday,
        time: this.formattedTime,
      });
    },
    everyMonthText() {
      return sprintf(s__('Every month (Day %{day} at %{time})'), {
        day: this.randomDay,
        time: this.formattedTime,
      });
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
  // If at the mounting stage the default is still an empty string, we
  // know we are not editing an existing field so we update it so
  // that the default is the first radio option
  mounted() {
    if (this.cronInterval === '') {
      this.cronInterval = this.cronIntervalPresets.everyDay;
    }
  },
  methods: {
    setCustomInput(e) {
      if (!this.isEditingCustom) {
        this.isEditingCustom = true;
        this.$refs.customInput.click();
        // Because we need to manually trigger the click on the radio btn,
        // it will add a space to update the v-model. If the user is typing
        // and the space is added, it will feel very unituitive so we reset
        // the value to the original
        this.cronInterval = e.target.value;
      }
      if (this.intervalIsPreset) {
        this.isEditingCustom = false;
      }
    },
    toggleCustomInput(shouldEnable) {
      this.isEditingCustom = shouldEnable;

      if (shouldEnable) {
        // We need to change the value so other radios don't remain selected
        // because the model (cronInterval) hasn't changed. The server trims it.
        this.cronInterval = `${this.cronInterval} `;
      }
    },
    generateRandomHour() {
      return Math.floor(Math.random() * 23);
    },
    generateRandomWeekDayIndex() {
      return Math.floor(Math.random() * 6);
    },
    generateRandomDay() {
      return Math.floor(Math.random() * 28);
    },
  },
};
</script>

<template>
  <div class="interval-pattern-form-group">
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

      <label class="label-bold" for="every-day">
        {{ everyDayText }}
      </label>
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
        {{ everyWeekText }}
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
        {{ everyMonthText }}
      </label>
    </div>

    <div class="cron-preset-radio-input">
      <input
        id="custom"
        ref="customInput"
        v-model="cronInterval"
        :name="inputNameAttribute"
        :value="cronInterval"
        class="label-bold"
        type="radio"
        @click="toggleCustomInput(true)"
      />

      <label for="custom"> {{ s__('PipelineSheduleIntervalPattern|Custom') }} </label>

      <gl-sprintf :message="__('(%{linkStart}Cron syntax%{linkEnd})')">
        <template #link="{content}">
          <gl-link :href="cronSyntaxUrl" target="_blank" class="gl-font-sm">
            {{ content }}
          </gl-link>
        </template>
      </gl-sprintf>
    </div>

    <div class="cron-interval-input-wrapper">
      <input
        id="schedule_cron"
        v-model="cronInterval"
        :placeholder="__('Define a custom pattern with cron syntax')"
        :name="inputNameAttribute"
        class="form-control inline cron-interval-input"
        type="text"
        required="true"
        @input="setCustomInput"
      />
    </div>
  </div>
</template>
