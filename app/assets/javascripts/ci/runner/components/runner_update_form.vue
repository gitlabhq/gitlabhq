<script>
import {
  GlButton,
  GlIcon,
  GlForm,
  GlFormCheckbox,
  GlFormGroup,
  GlFormInputGroup,
  GlSkeletonLoader,
  GlTooltipDirective,
} from '@gitlab/ui';
import {
  modelToUpdateMutationVariables,
  runnerToModel,
} from 'ee_else_ce/ci/runner/runner_update_form_utils';
import { createAlert, VARIANT_SUCCESS } from '~/alert';
import { redirectTo } from '~/lib/utils/url_utility'; // eslint-disable-line import/no-deprecated
import { __ } from '~/locale';
import { captureException } from '~/ci/runner/sentry_utils';
import { ACCESS_LEVEL_NOT_PROTECTED, ACCESS_LEVEL_REF_PROTECTED, PROJECT_TYPE } from '../constants';
import runnerUpdateMutation from '../graphql/edit/runner_update.mutation.graphql';
import { saveAlertToLocalStorage } from '../local_storage_alert/save_alert_to_local_storage';

export default {
  name: 'RunnerUpdateForm',
  components: {
    GlButton,
    GlIcon,
    GlForm,
    GlFormCheckbox,
    GlFormGroup,
    GlFormInputGroup,
    GlSkeletonLoader,
    RunnerMaintenanceNoteField: () =>
      import('ee_component/ci/runner/components/runner_maintenance_note_field.vue'),
    RunnerUpdateCostFactorFields: () =>
      import('ee_component/ci/runner/components/runner_update_cost_factor_fields.vue'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
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
      model: runnerToModel(this.runner),
    };
  },
  computed: {
    canBeLockedToProject() {
      return this.runner?.runnerType === PROJECT_TYPE;
    },
  },
  watch: {
    runner(newVal, oldVal) {
      if (oldVal === null) {
        this.model = runnerToModel(newVal);
      }
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
      redirectTo(this.runnerPath); // eslint-disable-line import/no-deprecated
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
    <h4 class="gl-font-lg gl-my-5">{{ s__('Runners|Details') }}</h4>

    <gl-skeleton-loader v-if="loading" />

    <template v-else>
      <gl-form-group :label="__('Description')" data-testid="runner-field-description">
        <gl-form-input-group v-model="model.description" />
      </gl-form-group>
      <runner-maintenance-note-field v-model="model.maintenanceNote" />
    </template>

    <hr />

    <h4 class="gl-font-lg gl-my-5">{{ s__('Runners|Configuration') }}</h4>

    <template v-if="loading">
      <gl-skeleton-loader v-for="i in 3" :key="i" />
    </template>
    <template v-else>
      <div class="gl-mb-5">
        <gl-form-checkbox
          v-model="model.active"
          data-testid="runner-field-paused"
          :value="false"
          :unchecked-value="true"
        >
          {{ __('Paused') }}
          <template #help>
            {{ s__('Runners|Stop the runner from accepting new jobs.') }}
          </template>
        </gl-form-checkbox>

        <gl-form-checkbox
          v-model="model.accessLevel"
          data-testid="runner-field-protected"
          :value="$options.ACCESS_LEVEL_REF_PROTECTED"
          :unchecked-value="$options.ACCESS_LEVEL_NOT_PROTECTED"
        >
          {{ __('Protected') }}
          <template #help>
            {{ s__('Runners|Use the runner on pipelines for protected branches only.') }}
          </template>
        </gl-form-checkbox>

        <gl-form-checkbox v-model="model.runUntagged" data-testid="runner-field-run-untagged">
          {{ __('Run untagged jobs') }}
          <template #help>
            {{ s__('Runners|Use the runner for jobs without tags, in addition to tagged jobs.') }}
          </template>
        </gl-form-checkbox>

        <gl-form-checkbox
          v-if="canBeLockedToProject"
          v-model="model.locked"
          data-testid="runner-field-locked"
        >
          {{ __('Lock to current projects') }} <gl-icon name="lock" />
          <template #help>
            {{
              s__(
                'Runners|Use the runner for the currently assigned projects only. Only administrators can change the assigned projects.',
              )
            }}
          </template>
        </gl-form-checkbox>
      </div>

      <gl-form-group
        data-testid="runner-field-max-timeout"
        :label="__('Maximum job timeout')"
        :description="
          s__(
            'Runners|Enter the number of seconds. This timeout takes precedence over lower timeouts set for the project.',
          )
        "
      >
        <gl-form-input-group v-model.number="model.maximumTimeout" type="number" />
      </gl-form-group>

      <gl-form-group
        data-testid="runner-field-tags"
        :label="__('Tags')"
        :description="
          __(
            'You can set up jobs to only use runners with specific tags. Separate tags with commas.',
          )
        "
      >
        <gl-form-input-group v-model="model.tagList" />
      </gl-form-group>

      <runner-update-cost-factor-fields v-model="model" />
    </template>

    <div class="gl-mt-6">
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
