<script>
import {
  GlFormRadio,
  GlFormRadioGroup,
  GlIcon,
  GlLink,
  GlSprintf,
  GlTooltipDirective,
} from '@gitlab/ui';
import { getWeekdayNames } from '~/lib/utils/datetime_utility';
import { __, s__, sprintf } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

const KEY_EVERY_DAY = 'everyDay';
const KEY_EVERY_WEEK = 'everyWeek';
const KEY_EVERY_MONTH = 'everyMonth';
const KEY_CUSTOM = 'custom';

export default {
  components: {
    GlFormRadio,
    GlFormRadioGroup,
    GlIcon,
    GlLink,
    GlSprintf,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    initialCronInterval: {
      type: String,
      required: false,
      default: '',
    },
    dailyLimit: {
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
      radioValue: this.initialCronInterval ? KEY_CUSTOM : KEY_EVERY_DAY,
      cronInterval: this.initialCronInterval,
      cronSyntaxUrl: 'https://en.wikipedia.org/wiki/Cron',
    };
  },
  computed: {
    cronIntervalPresets() {
      return {
        [KEY_EVERY_DAY]: `0 ${this.randomHour} * * *`,
        [KEY_EVERY_WEEK]: `0 ${this.randomHour} * * ${this.randomWeekDayIndex}`,
        [KEY_EVERY_MONTH]: `0 ${this.randomHour} ${this.randomDay} * *`,
      };
    },
    formattedTime() {
      if (this.randomHour > 12) {
        return `${this.randomHour - 12}:00pm`;
      } else if (this.randomHour === 12) {
        return `12:00pm`;
      }
      return `${this.randomHour}:00am`;
    },
    radioOptions() {
      return [
        {
          value: KEY_EVERY_DAY,
          text: sprintf(s__(`Every day (at %{time})`), { time: this.formattedTime }),
        },
        {
          value: KEY_EVERY_WEEK,
          text: sprintf(s__('Every week (%{weekday} at %{time})'), {
            weekday: this.weekday,
            time: this.formattedTime,
          }),
        },
        {
          value: KEY_EVERY_MONTH,
          text: sprintf(s__('Every month (Day %{day} at %{time})'), {
            day: this.randomDay,
            time: this.formattedTime,
          }),
        },
        {
          value: KEY_CUSTOM,
          text: s__('PipelineScheduleIntervalPattern|Custom (%{linkStart}Cron syntax%{linkEnd})'),
          link: this.cronSyntaxUrl,
        },
      ];
    },
    weekday() {
      return getWeekdayNames()[this.randomWeekDayIndex];
    },
    parsedDailyLimit() {
      return this.dailyLimit ? (24 * 60) / this.dailyLimit : null;
    },
    scheduleDailyLimitMsg() {
      return sprintf(
        __(
          'Scheduled pipelines cannot run more frequently than once per %{limit} minutes. A pipeline configured to run more frequently only starts after %{limit} minutes have elapsed since the last time it ran.',
        ),
        { limit: this.parsedDailyLimit },
      );
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
    radioValue: {
      immediate: true,
      handler(val) {
        if (val !== KEY_CUSTOM) {
          this.cronInterval = this.cronIntervalPresets[val];
        }
      },
    },
  },
  methods: {
    onCustomInput() {
      this.radioValue = KEY_CUSTOM;
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
    showDailyLimitMessage({ value }) {
      return (
        value === KEY_CUSTOM && this.glFeatures.ciDailyLimitForPipelineSchedules && this.dailyLimit
      );
    },
  },
};
</script>

<template>
  <div>
    <gl-form-radio-group v-model="radioValue" :name="inputNameAttribute">
      <gl-form-radio
        v-for="option in radioOptions"
        :key="option.value"
        :value="option.value"
        :data-testid="option.value"
      >
        <gl-sprintf v-if="option.link" :message="option.text">
          <template #link="{ content }">
            <gl-link :href="option.link" target="_blank" class="gl-font-sm">
              {{ content }}
            </gl-link>
          </template>
        </gl-sprintf>

        <template v-else>{{ option.text }}</template>

        <gl-icon
          v-if="showDailyLimitMessage(option)"
          v-gl-tooltip.hover
          name="question"
          :title="scheduleDailyLimitMsg"
        />
      </gl-form-radio>
    </gl-form-radio-group>
    <input
      id="schedule_cron"
      v-model="cronInterval"
      :placeholder="__('Define a custom pattern with cron syntax')"
      :name="inputNameAttribute"
      class="form-control inline cron-interval-input gl-form-input"
      type="text"
      required="true"
      @input="onCustomInput"
    />
  </div>
</template>
