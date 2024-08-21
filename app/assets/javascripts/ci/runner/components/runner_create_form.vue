<script>
import { GlForm, GlButton } from '@gitlab/ui';
import RunnerFormFields from '~/ci/runner/components/runner_form_fields.vue';
import runnerCreateMutation from '~/ci/runner/graphql/new/runner_create.mutation.graphql';
import { modelToUpdateMutationVariables } from 'ee_else_ce/ci/runner/runner_update_form_utils';
import { captureException } from '../sentry_utils';
import {
  RUNNER_TYPES,
  DEFAULT_ACCESS_LEVEL,
  PROJECT_TYPE,
  GROUP_TYPE,
  I18N_CREATE_ERROR,
} from '../constants';

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
  },
  data() {
    return {
      saving: false,
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
    async onSubmit() {
      this.saving = true;

      try {
        const {
          data: {
            runnerCreate: { errors, runner },
          },
        } = await this.$apollo.mutate({
          mutation: runnerCreateMutation,
          variables: {
            input: this.mutationInput,
          },
        });

        if (errors?.length) {
          this.onError(new Error(errors.join(' ')), true);
          return;
        }

        if (!runner?.ephemeralRegisterUrl) {
          // runner is missing information, report issue and
          // fail navigation to register page.
          this.onError(new Error(I18N_CREATE_ERROR));
          return;
        }

        this.onSuccess(runner);
      } catch (error) {
        this.onError(error);
      }
    },
    onError(error, isValidationError = false) {
      if (!isValidationError) {
        captureException({ error, component: this.$options.name });
      }

      this.$emit('error', error);
      this.saving = false;
    },
    onSuccess(runner) {
      this.$emit('saved', runner);
    },
  },
};
</script>
<template>
  <gl-form @submit.prevent="onSubmit">
    <runner-form-fields v-model="runner" :runner-type="runnerType" />

    <div class="gl-mt-6 gl-flex">
      <gl-button type="submit" variant="confirm" class="js-no-auto-disable" :loading="saving">
        {{ s__('Runners|Create runner') }}
      </gl-button>
    </div>
  </gl-form>
</template>
