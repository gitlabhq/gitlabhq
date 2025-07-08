<script>
import { RUNNER_TYPES } from '../constants';
import RequiredFields from './runner_create_wizard_required_fields.vue';
import OptionalFields from './runner_create_wizard_optional_fields.vue';
import RunnerRegistration from './runner_create_wizard_registration.vue';

export default {
  name: 'RunnerCreateWizard',
  components: {
    RequiredFields,
    OptionalFields,
    RunnerRegistration,
  },
  props: {
    runnerType: {
      type: String,
      required: true,
      validator: (t) => RUNNER_TYPES.includes(t),
    },
    runnersPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      currentStep: 1,
      tags: '',
      runUntagged: false,
      newRunnerId: null,
    };
  },
  methods: {
    onNext() {
      this.currentStep += 1;
    },
    onBack() {
      this.currentStep -= 1;
    },
    onRequiredFieldsUpdate(requiredFields) {
      this.tags = requiredFields.tags;
      this.runUntagged = requiredFields.runUntagged;
    },
    onGetNewRunnerId(runnerId) {
      this.newRunnerId = runnerId;
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
    :is-run-untagged="runUntagged"
    :tag-list="tags"
    @next="onNext"
    @onRequiredFieldsUpdate="onRequiredFieldsUpdate"
  />
  <optional-fields
    v-else-if="currentStep === 2"
    :current-step="currentStep"
    :steps-total="$options.stepsTotal"
    :tags="tags"
    :run-untagged="runUntagged"
    :runner-type="runnerType"
    @next="onNext"
    @back="onBack"
    @onGetNewRunnerId="onGetNewRunnerId"
  />
  <runner-registration
    v-else-if="currentStep === 3"
    :current-step="currentStep"
    :steps-total="$options.stepsTotal"
    :runner-id="newRunnerId"
    :runners-path="runnersPath"
  />
</template>
