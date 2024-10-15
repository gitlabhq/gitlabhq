<script>
import { GlButton, GlForm } from '@gitlab/ui';
import RunnerFormFields from '~/ci/runner/components/runner_form_fields.vue';
import { createAlert, VARIANT_SUCCESS } from '~/alert';
import { visitUrl } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import { captureException } from '~/ci/runner/sentry_utils';

import {
  modelToUpdateMutationVariables,
  runnerToModel,
} from 'ee_else_ce/ci/runner/runner_update_form_utils';
import { ACCESS_LEVEL_NOT_PROTECTED, ACCESS_LEVEL_REF_PROTECTED } from '../constants';
import runnerUpdateMutation from '../graphql/edit/runner_update.mutation.graphql';
import { saveAlertToLocalStorage } from '../local_storage_alert/save_alert_to_local_storage';

export default {
  name: 'RunnerUpdateForm',
  components: {
    GlButton,
    GlForm,
    RunnerFormFields,
    RunnerUpdateCostFactorFields: () =>
      import('ee_component/ci/runner/components/runner_update_cost_factor_fields.vue'),
  },
  props: {
    runner: {
      type: Object,
      required: false,
      default: null,
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    runnerPath: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      saving: false,
      model: null,
    };
  },
  computed: {
    runnerType() {
      return this.runner?.runnerType;
    },
  },
  watch: {
    runner(val) {
      this.model = runnerToModel(val);
    },
  },
  methods: {
    async onSubmit() {
      this.saving = true;

      try {
        const {
          data: {
            runnerUpdate: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: runnerUpdateMutation,
          variables: modelToUpdateMutationVariables(this.model),
        });

        if (errors?.length) {
          this.onError(errors[0]);
        } else {
          this.onSuccess();
        }
      } catch (error) {
        const { message } = error;
        this.onError(message);
        captureException({ error, component: this.$options.name });
      }
    },
    onSuccess() {
      saveAlertToLocalStorage({ message: __('Changes saved.'), variant: VARIANT_SUCCESS });
      visitUrl(this.runnerPath);
    },
    onError(message) {
      this.saving = false;
      createAlert({ message });
    },
  },
  ACCESS_LEVEL_NOT_PROTECTED,
  ACCESS_LEVEL_REF_PROTECTED,
};
</script>
<template>
  <gl-form @submit.prevent="onSubmit">
    <runner-form-fields v-model="model" :loading="loading" :runner-type="runnerType" />
    <runner-update-cost-factor-fields v-model="model" :runner-type="runnerType" />

    <div class="gl-mt-6 gl-flex gl-gap-3">
      <gl-button
        type="submit"
        variant="confirm"
        class="js-no-auto-disable"
        :loading="loading || saving"
      >
        {{ __('Save changes') }}
      </gl-button>
      <gl-button :href="runnerPath">
        {{ __('Cancel') }}
      </gl-button>
    </div>
  </gl-form>
</template>
