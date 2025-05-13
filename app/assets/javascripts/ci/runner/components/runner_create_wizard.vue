<script>
import RequiredFields from './runner_create_wizard_required_fields.vue';

export default {
  name: 'RunnerCreateWizard',
  components: {
    RequiredFields,
  },
  data() {
    return {
      currentStep: 1,
      tags: '',
      runUntagged: false,
    };
  },
  methods: {
    onNext() {
      this.currentStep += 1;
    },
    onRequiredFieldsUpdate(requiredFields) {
      this.tags = requiredFields.tags;
      this.runUntagged = requiredFields.runUntagged;
    },
  },
  stepsTotal: 3,
};
</script>
<template>
  <required-fields
    v-if="currentStep === 1"
    :current-step="currentStep"
    :steps-total="$options.stepsTotal"
    @next="onNext"
    @onRequiredFieldsUpdate="onRequiredFieldsUpdate"
  />
</template>
