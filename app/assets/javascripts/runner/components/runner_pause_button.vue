<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import runnerToggleActiveMutation from '~/runner/graphql/runner_toggle_active.mutation.graphql';
import { createAlert } from '~/flash';
import { captureException } from '~/runner/sentry_utils';
import { I18N_PAUSE, I18N_RESUME } from '../constants';

export default {
  name: 'RunnerPauseButton',
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    runner: {
      type: Object,
      required: true,
    },
    compact: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      updating: false,
    };
  },
  computed: {
    isActive() {
      return this.runner.active;
    },
    icon() {
      return this.isActive ? 'pause' : 'play';
    },
    label() {
      return this.isActive ? I18N_PAUSE : I18N_RESUME;
    },
    buttonContent() {
      if (this.compact) {
        return null;
      }
      return this.label;
    },
    ariaLabel() {
      if (this.compact) {
        return this.label;
      }
      return null;
    },
    tooltip() {
      // Only show tooltip when compact.
      // Also prevent a "sticky" tooltip: If this button is
      // disabled, mouseout listeners don't run leaving the tooltip stuck
      if (this.compact && !this.updating) {
        return this.label;
      }
      return '';
    },
  },
  methods: {
    async onToggle() {
      this.updating = true;
      try {
        const input = {
          id: this.runner.id,
          active: !this.isActive,
        };

        const {
          data: {
            runnerUpdate: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: runnerToggleActiveMutation,
          variables: {
            input,
          },
        });

        if (errors && errors.length) {
          throw new Error(errors.join(' '));
        }
      } catch (e) {
        this.onError(e);
      } finally {
        this.updating = false;
      }
    },
    onError(error) {
      const { message } = error;
      createAlert({ message });

      this.reportToSentry(error);
    },
    reportToSentry(error) {
      captureException({ error, component: this.$options.name });
    },
  },
};
</script>

<template>
  <gl-button
    v-gl-tooltip.hover.viewport="tooltip"
    v-bind="$attrs"
    :aria-label="ariaLabel"
    :icon="icon"
    :loading="updating"
    @click="onToggle"
    v-on="$listeners"
  >
    <!--
      Use <template v-if> to ensure a square button is shown when compact: true.
      Sending empty content will still show a distorted/rectangular button.
    -->
    <template v-if="buttonContent">{{ buttonContent }}</template>
  </gl-button>
</template>
