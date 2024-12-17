<script>
import { GlFormRadio, GlFormRadioGroup, GlLink, GlTooltipDirective } from '@gitlab/ui';
import { getWeekdayNames } from '~/lib/utils/datetime_utility';
import { __, s__, sprintf } from '~/locale';
import { DOCS_URL_IN_EE_DIR } from 'jh_else_ce/lib/utils/url_utility';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';

const KEY_EVERY_DAY = 'everyDay';
const KEY_EVERY_WEEK = 'everyWeek';
const KEY_EVERY_MONTH = 'everyMonth';
const KEY_CUSTOM = 'custom';

const MINUTE = 60; // minute between 0-59
const HOUR = 24; // hour between 0-23
const WEEKDAY_INDEX = 7; // week index Sun-Sat
const DAY = 29; // day between 0-28
const getRandomCronValue = (max) => Math.floor(Math.random() * max);

export default {
  components: {
    GlFormRadio,
    GlFormRadioGroup,
    GlLink,
    HelpIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
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
    sendNativeErrors: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  data() {
    return {
      isEditingCustom: false,
      randomMinute: getRandomCronValue(MINUTE),
      randomHour: getRandomCronValue(HOUR),
      randomWeekDayIndex: getRandomCronValue(WEEKDAY_INDEX),
      randomDay: getRandomCronValue(DAY),
      inputNameAttribute: 'schedule[cron]',
      radioValue: this.initialCronInterval ? KEY_CUSTOM : KEY_EVERY_DAY,
      cronInterval: this.initialCronInterval,
      cronSyntaxUrl: `${DOCS_URL_IN_EE_DIR}/topics/cron/`,
    };
  },
  computed: {
    cronIntervalPresets() {
      return {
        [KEY_EVERY_DAY]: `${this.randomMinute} ${this.randomHour} * * *`,
        [KEY_EVERY_WEEK]: `${this.randomMinute} ${this.randomHour} * * ${this.randomWeekDayIndex}`,
        [KEY_EVERY_MONTH]: `${this.randomMinute} ${this.randomHour} ${this.randomDay} * *`,
      };
    },
    formattedMinutes() {
      return String(this.randomMinute).padStart(2, '0');
    },
    formattedTime() {
      if (this.randomHour > 12) {
        return `${this.randomHour - 12}:${this.formattedMinutes}pm`;
      }
      if (this.randomHour === 12) {
        return `12:${this.formattedMinutes}pm`;
      }
      return `${this.randomHour}:${this.formattedMinutes}am`;
    },
    radioOptions() {
      return [
        {
          value: KEY_EVERY_DAY,
          text: sprintf(__(`Every day (at %{time})`), { time: this.formattedTime }),
        },
        {
          value: KEY_EVERY_WEEK,
          text: sprintf(__('Every week (%{weekday} at %{time})'), {
            weekday: this.weekday,
            time: this.formattedTime,
          }),
        },
        {
          value: KEY_EVERY_MONTH,
          text: sprintf(__('Every month (Day %{day} at %{time})'), {
            day: this.randomDay,
            time: this.formattedTime,
          }),
        },
        {
          value: KEY_CUSTOM,
          text: s__('PipelineScheduleIntervalPattern|Custom'),
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
    cronInterval(val) {
      // updates field validation state when model changes, as
      // glFieldError only updates on input.
      if (this.sendNativeErrors) {
        this.$nextTick(() => {
          gl.pipelineScheduleFieldErrors.updateFormValidityState();
        });
      }

      this.$emit('cronValue', val);
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
    showDailyLimitMessage({ value }) {
      return value === KEY_CUSTOM && this.dailyLimit;
    },
  },
  i18n: {
    learnCronSyntax: s__('PipelineScheduleIntervalPattern|Set a custom interval with Cron syntax.'),
    cronSyntaxLink: s__('PipelineScheduleIntervalPattern|What is Cron syntax?'),
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
        {{ option.text }}

        <help-icon
          v-if="showDailyLimitMessage(option)"
          v-gl-tooltip.hover
          :title="scheduleDailyLimitMsg"
          data-testid="daily-limit"
        />
      </gl-form-radio>
    </gl-form-radio-group>
    <input
      id="schedule_cron"
      v-model="cronInterval"
      :placeholder="__('Define a custom pattern with cron syntax')"
      :name="inputNameAttribute"
      class="form-control cron-interval-input gl-form-input gl-inline-block"
      type="text"
      required="true"
      @input="onCustomInput"
    />
    <p class="gl-mb-0 gl-mt-1 gl-text-subtle">
      {{ $options.i18n.learnCronSyntax }}
      <gl-link :href="cronSyntaxUrl" target="_blank">
        {{ $options.i18n.cronSyntaxLink }}
      </gl-link>
    </p>
  </div>
</template>
