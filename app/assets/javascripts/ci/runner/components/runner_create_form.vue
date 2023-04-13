<script>
import { GlForm, GlButton } from '@gitlab/ui';
import RunnerFormFields from '~/ci/runner/components/runner_form_fields.vue';
import runnerCreateMutation from '~/ci/runner/graphql/new/runner_create.mutation.graphql';
import { modelToUpdateMutationVariables } from 'ee_else_ce/ci/runner/runner_update_form_utils';
import { captureException } from '../sentry_utils';
import { DEFAULT_ACCESS_LEVEL, INSTANCE_TYPE } from '../constants';

export default {
  name: 'RunnerCreateForm',
  components: {
    GlForm,
    GlButton,
    RunnerFormFields,
  },
  data() {
    return {
      saving: false,
      runner: {
        runnerType: INSTANCE_TYPE,
        description: '',
        maintenanceNote: '',
        paused: false,
        accessLevel: DEFAULT_ACCESS_LEVEL,
        runUntagged: false,
        tagList: '',
        maximumTimeout: '',
      },
    };
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
          variables: modelToUpdateMutationVariables(this.runner),
        });

        if (errors?.length) {
          this.$emit('error', new Error(errors.join(' ')));
        } else {
          this.onSuccess(runner);
        }
      } catch (error) {
        captureException({ error, component: this.$options.name });
        this.$emit('error', error);
      } finally {
        this.saving = false;
      }
    },
    onSuccess(runner) {
      this.$emit('saved', runner);
    },
  },
};
</script>
<template>
  <gl-form @submit.prevent="onSubmit">
    <runner-form-fields v-model="runner" />

    <div class="gl-display-flex">
      <gl-button type="submit" variant="confirm" class="js-no-auto-disable" :loading="saving">
        {{ __('Submit') }}
      </gl-button>
    </div>
  </gl-form>
</template>
