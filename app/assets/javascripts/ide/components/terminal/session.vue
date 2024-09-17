<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlButton } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState } from 'vuex';
import { __ } from '~/locale';
import { isEndingStatus } from '../../stores/modules/terminal/utils';
import Terminal from './terminal.vue';

export default {
  components: {
    Terminal,
    GlButton,
  },
  computed: {
    ...mapState('terminal', ['session']),
    actionButton() {
      if (isEndingStatus(this.session.status)) {
        return {
          action: () => this.restartSession(),
          variant: 'confirm',
          category: 'primary',
          text: __('Restart Terminal'),
        };
      }

      return {
        action: () => this.stopSession(),
        variant: 'danger',
        category: 'secondary',
        text: __('Stop Terminal'),
      };
    },
  },
  methods: {
    ...mapActions('terminal', ['restartSession', 'stopSession']),
  },
};
</script>

<template>
  <div v-if="session" class="ide-terminal flex-column gl-flex">
    <header class="ide-job-header gl-flex gl-items-center">
      <h5>{{ __('Web Terminal') }}</h5>
      <div class="ml-auto align-self-center">
        <gl-button
          v-if="actionButton"
          :variant="actionButton.variant"
          :category="actionButton.category"
          @click="actionButton.action"
          >{{ actionButton.text }}</gl-button
        >
      </div>
    </header>
    <terminal :terminal-path="session.terminalPath" :status="session.status" />
  </div>
</template>
