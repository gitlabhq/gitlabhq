<script>
import { GlPopover, GlSprintf, GlButton, GlAlert } from '@gitlab/ui';
import { STEPS, STEPSTATES } from '../constants';
import {
  isWalkthroughEnabled,
  getExperimentSettings,
  setExperimentSettings,
  track,
} from '../utils';

export default {
  target: '#js-code-quality-walkthrough',
  components: {
    GlPopover,
    GlSprintf,
    GlButton,
    GlAlert,
  },
  props: {
    step: {
      type: String,
      required: true,
    },
    link: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      dismissedSettings: getExperimentSettings(),
      currentStep: STEPSTATES[this.step],
    };
  },
  computed: {
    isPopoverVisible() {
      return (
        [
          STEPS.commitCiFile,
          STEPS.runningPipeline,
          STEPS.successPipeline,
          STEPS.failedPipeline,
        ].includes(this.step) &&
        isWalkthroughEnabled() &&
        !this.isDismissed
      );
    },
    isAlertVisible() {
      return this.step === STEPS.troubleshootJob && isWalkthroughEnabled() && !this.isDismissed;
    },
    isDismissed() {
      return this.dismissedSettings[this.step];
    },
    title() {
      return this.currentStep?.title || '';
    },
    body() {
      return this.currentStep?.body || '';
    },
    buttonText() {
      return this.currentStep?.buttonText || '';
    },
    buttonLink() {
      return [STEPS.successPipeline, STEPS.failedPipeline].includes(this.step) ? this.link : '';
    },
    placement() {
      return this.currentStep?.placement || 'bottom';
    },
    offset() {
      return this.currentStep?.offset || 0;
    },
  },
  created() {
    this.trackDisplayed();
  },
  updated() {
    this.trackDisplayed();
  },
  methods: {
    onDismiss() {
      this.$set(this.dismissedSettings, this.step, true);
      setExperimentSettings(this.dismissedSettings);
      const action = [STEPS.successPipeline, STEPS.failedPipeline].includes(this.step)
        ? 'view_logs'
        : 'dismissed';
      this.trackAction(action);
    },
    trackDisplayed() {
      if (this.isPopoverVisible || this.isAlertVisible) {
        this.trackAction('displayed');
      }
    },
    trackAction(action) {
      track(`${this.step}_${action}`);
    },
  },
};
</script>

<template>
  <div>
    <gl-popover
      v-if="isPopoverVisible"
      :key="step"
      :target="$options.target"
      :placement="placement"
      :offset="offset"
      show
      triggers="manual"
      container="viewport"
    >
      <template #title>
        <gl-sprintf :message="title">
          <template #emoji="{ content }">
            <gl-emoji class="gl-mr-2" :data-name="content"
          /></template>
        </gl-sprintf>
      </template>
      <gl-sprintf :message="body">
        <template #strong="{ content }">
          <strong>{{ content }}</strong>
        </template>
        <template #lineBreak>
          <div class="gl-mt-5"></div>
        </template>
        <template #emoji="{ content }">
          <gl-emoji :data-name="content" />
        </template>
      </gl-sprintf>
      <div class="gl-mt-2 gl-text-right">
        <gl-button category="tertiary" variant="link" :href="buttonLink" @click="onDismiss">
          {{ buttonText }}
        </gl-button>
      </div>
    </gl-popover>
    <gl-alert
      v-if="isAlertVisible"
      variant="tip"
      :title="title"
      :primary-button-text="buttonText"
      :primary-button-link="link"
      class="gl-my-5"
      @primaryAction="trackAction('clicked')"
      @dismiss="onDismiss"
    >
      {{ body }}
    </gl-alert>
  </div>
</template>
