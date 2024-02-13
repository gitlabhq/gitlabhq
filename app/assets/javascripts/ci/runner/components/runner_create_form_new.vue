<script>
import { GlForm, GlButton } from '@gitlab/ui';
import RunnerFormFields from '~/ci/runner/components/runner_form_fields.vue';
import { modelToUpdateMutationVariables } from 'ee_else_ce/ci/runner/runner_update_form_utils';
import { RUNNER_TYPES, DEFAULT_ACCESS_LEVEL, PROJECT_TYPE, GROUP_TYPE } from '../constants';

export default {
  name: 'RunnerCreateForm',
  components: {
    GlForm,
    GlButton,
    RunnerFormFields,
  },
  props: {
    runnerType: {
      type: String,
      required: true,
      validator: (t) => RUNNER_TYPES.includes(t),
    },
    groupId: {
      type: String,
      required: false,
      default: null,
    },
    projectId: {
      type: String,
      required: false,
      default: null,
    },
    showPrevious: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  data() {
    return {
      runner: {
        runnerType: this.runnerType,
        description: '',
        maintenanceNote: '',
        paused: false,
        accessLevel: DEFAULT_ACCESS_LEVEL,
        runUntagged: false,
        locked: false,
        tagList: '',
        maximumTimeout: '',
      },
    };
  },
  computed: {
    mutationInput() {
      const { input } = modelToUpdateMutationVariables(this.runner);

      if (this.runnerType === GROUP_TYPE) {
        return {
          ...input,
          groupId: this.groupId,
        };
      }
      if (this.runnerType === PROJECT_TYPE) {
        return {
          ...input,
          projectId: this.projectId,
        };
      }
      return input;
    },
  },
  methods: {
    onSubmit() {
      this.$emit('createRunner', this.mutationInput);
    },
    onPrevious() {
      this.$emit('previous', this.mutationInput);
    },
  },
};
</script>
<template>
  <gl-form @submit.prevent="onSubmit">
    <runner-form-fields v-model="runner" :runner-type="runnerType" />

    <div class="gl-display-flex gl-mt-6">
      <gl-button v-if="showPrevious" class="gl-mr-4" data-testid="back-button" @click="onPrevious">
        {{ __('Back') }}
      </gl-button>
      <gl-button type="submit" variant="confirm" class="js-no-auto-disable">
        {{ s__('Runners|Create runner') }}
      </gl-button>
    </div>
  </gl-form>
</template>
