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
    GlModal: GlModalDirective,
  },
  modalId: 'runner-instructions-modal',
  i18n: {
    buttonText: s__('Runners|Show runner installation instructions'),
  },
};
</script>
<template>
  <div>
    <gl-button v-gl-modal="$options.modalId" class="gl-mt-4" data-testid="show-modal-button">
      {{ $options.i18n.buttonText }}
    </gl-button>
    <runner-instructions-modal :modal-id="$options.modalId" />
  </div>
</template>
