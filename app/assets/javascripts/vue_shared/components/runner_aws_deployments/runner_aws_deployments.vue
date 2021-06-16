<script>
import { GlButton, GlModalDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import RunnerAwsDeploymentsModal from './runner_aws_deployments_modal.vue';

export default {
  components: {
    GlButton,
    RunnerAwsDeploymentsModal,
  },
  directives: {
    GlModalDirective,
  },
  modalId: 'runner-aws-deployments-modal',
  i18n: {
    buttonText: s__('Runners|Deploy GitLab Runner in AWS'),
  },
  data() {
    return {
      opened: false,
    };
  },
  methods: {
    onClick() {
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
      variant="confirm"
      @click="onClick"
    >
      {{ $options.i18n.buttonText }}
    </gl-button>
    <runner-aws-deployments-modal v-if="opened" :modal-id="$options.modalId" />
  </div>
</template>
