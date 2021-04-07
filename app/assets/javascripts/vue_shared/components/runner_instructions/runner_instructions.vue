<script>
import { GlButton, GlModalDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import RunnerInstructionsModal from './runner_instructions_modal.vue';

export default {
  components: {
    GlButton,
    RunnerInstructionsModal,
  },
  directives: {
    GlModalDirective,
  },
  modalId: 'runner-instructions-modal',
  i18n: {
    buttonText: s__('Runners|Show Runner installation instructions'),
  },
  data() {
    return {
      opened: false,
    };
  },
  methods: {
    onClick() {
      // lazily mount modal to prevent premature instructions requests
      this.opened = true;
    },
  },
};
</script>
<template>
  <div>
    <gl-button
      v-gl-modal-directive="$options.modalId"
      class="gl-mt-4"
      data-testid="show-modal-button"
      @click="onClick"
    >
      {{ $options.i18n.buttonText }}
    </gl-button>
    <runner-instructions-modal v-if="opened" :modal-id="$options.modalId" />
  </div>
</template>
