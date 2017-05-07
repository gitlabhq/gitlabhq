import Vue from 'vue';

const inputNameAttribute = 'schedule[cron]';

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
      inputNameAttribute,
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
    showUnsetWarning() {
      return this.cronInterval === '';
    },
    intervalIsPreset() {
      return _.contains(this.cronIntervalPresets, this.cronInterval);
    },
    // The text input is editable when there's a custom interval, or when it's
    // a preset interval and the user clicks the 'custom' radio button
    isEditable() {
      return !!(this.customInputEnabled || !this.intervalIsPreset);
    },
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
  created() {
    if (this.intervalIsPreset) {
      this.enableCustomInput = false;
    }
  },
  watch: {
    cronInterval() {
      // updates field validation state when model changes, as
      // glFieldError only updates on input.
      Vue.nextTick(() => {
        gl.pipelineScheduleFieldErrors.updateFormValidityState();
      });
    },
  },
  template: `
    <div class="interval-pattern-form-group">
      <input
        id="custom"
        class="label-light"
        type="radio"
        :name="inputNameAttribute"
        :value="cronInterval"
        :checked="isEditable"
        @click="toggleCustomInput(true)"
      />

      <label for="custom">
        Custom
      </label>

      <span class="cron-syntax-link-wrap">
        (<a :href="cronSyntaxUrl" target="_blank">Cron syntax</a>)
      </span>

      <input
        id="every-day"
        class="label-light"
        type="radio"
        v-model="cronInterval"
        :name="inputNameAttribute"
        :value="cronIntervalPresets.everyDay"
        @click="toggleCustomInput(false)"
      />

      <label class="label-light" for="every-day">
        Every day (at 4:00am)
      </label>

      <input
        id="every-week"
        class="label-light"
        type="radio"
        v-model="cronInterval"
        :name="inputNameAttribute"
        :value="cronIntervalPresets.everyWeek"
        @click="toggleCustomInput(false)"
      />

      <label class="label-light" for="every-week">
        Every week (Sundays at 4:00am)
      </label>

      <input
        id="every-month"
        class="label-light"
        type="radio"
        v-model="cronInterval"
        :name="inputNameAttribute"
        :value="cronIntervalPresets.everyMonth"
        @click="toggleCustomInput(false)"
      />

      <label class="label-light" for="every-month">
        Every month (on the 1st at 4:00am)
      </label>

      <div class="cron-interval-input-wrapper col-md-6">
        <input
          id="schedule_cron"
          class="form-control inline cron-interval-input"
          type="text"
          placeholder="Define a custom pattern with cron syntax"
          required="true"
          v-model="cronInterval"
          :name="inputNameAttribute"
          :disabled="!isEditable"
        />
      </div>
      <span class="cron-unset-status col-md-3" v-if="showUnsetWarning">
        Schedule not yet set
      </span>
    </div>
  `,
};
