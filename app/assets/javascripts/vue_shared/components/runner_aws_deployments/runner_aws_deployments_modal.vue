<script>
import { GlModal } from '@gitlab/ui';
import { s__ } from '~/locale';
import RunnerAwsInstructions from '~/vue_shared/components/runner_instructions/instructions/runner_aws_instructions.vue';

export default {
  components: {
    GlModal,
    RunnerAwsInstructions,
  },
  props: {
    modalId: {
      type: String,
      required: true,
    },
  },
  methods: {
    onClose() {
      this.$refs.modal.close();
    },
  },
  i18n_title: s__('Runners|Deploy GitLab Runner in AWS'),
};
</script>
<template>
  <gl-modal ref="modal" :modal-id="modalId" :title="$options.i18n_title" hide-footer size="sm">
    <runner-aws-instructions @close="onClose" />
  </gl-modal>
</template>
