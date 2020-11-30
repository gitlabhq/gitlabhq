<script>
import { mapActions, mapState } from 'vuex';
import { GlButton } from '@gitlab/ui';
import { __ } from '~/locale';
import Terminal from './terminal.vue';
import { isEndingStatus } from '../../stores/modules/terminal/utils';

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
          variant: 'info',
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
  <div v-if="session" class="ide-terminal d-flex flex-column">
    <header class="ide-job-header d-flex align-items-center">
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
