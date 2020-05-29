<script>
import { mapActions, mapState } from 'vuex';
import { __ } from '~/locale';
import Terminal from './terminal.vue';
import { isEndingStatus } from '../../stores/modules/terminal/utils';

export default {
  components: {
    Terminal,
  },
  computed: {
    ...mapState('terminal', ['session']),
    actionButton() {
      if (isEndingStatus(this.session.status)) {
        return {
          action: () => this.restartSession(),
          text: __('Restart Terminal'),
          class: 'btn-primary',
        };
      }

      return {
        action: () => this.stopSession(),
        text: __('Stop Terminal'),
        class: 'btn-inverted btn-remove',
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
        <button
          v-if="actionButton"
          type="button"
          class="btn btn-sm"
          :class="actionButton.class"
          @click="actionButton.action"
        >
          {{ actionButton.text }}
        </button>
      </div>
    </header>
    <terminal :terminal-path="session.terminalPath" :status="session.status" />
  </div>
</template>
