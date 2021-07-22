<script>
import {
  GlButton,
  GlForm,
  GlFormCheckbox,
  GlFormGroup,
  GlFormInputGroup,
  GlTooltipDirective,
} from '@gitlab/ui';
import {
  modelToUpdateMutationVariables,
  runnerToModel,
} from 'ee_else_ce/runner/runner_details/runner_update_form_utils';
import createFlash, { FLASH_TYPES } from '~/flash';
import { __ } from '~/locale';
import { captureException } from '~/runner/sentry_utils';
import { ACCESS_LEVEL_NOT_PROTECTED, ACCESS_LEVEL_REF_PROTECTED, PROJECT_TYPE } from '../constants';
import runnerUpdateMutation from '../graphql/runner_update.mutation.graphql';

export default {
  name: 'RunnerUpdateForm',
  components: {
    GlButton,
    GlForm,
    GlFormCheckbox,
    GlFormGroup,
    GlFormInputGroup,
    RunnerUpdateCostFactorFields: () =>
      import('ee_component/runner/components/runner_update_cost_factor_fields.vue'),
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
    readonlyIpAddress() {
      return this.runner?.ipAddress;
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
          // Validation errors need not be thrown
          createFlash({ message: errors[0] });
          return;
        }

        this.onSuccess();
      } catch (error) {
        const { message } = error;
        createFlash({ message });

        this.reportToSentry(error);
      } finally {
        this.saving = false;
      }
    },
    onSuccess() {
      createFlash({ message: __('Changes saved.'), type: FLASH_TYPES.SUCCESS });
      this.model = runnerToModel(this.runner);
    },
    reportToSentry(error) {
      captureException({ error, component: this.$options.name });
    },
  },
  ACCESS_LEVEL_NOT_PROTECTED,
  ACCESS_LEVEL_REF_PROTECTED,
};
</script>
<template>
  <gl-form @submit.prevent="onSubmit">
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
      v-model="model.locked"
      data-testid="runner-field-locked"
      :disabled="!canBeLockedToProject"
    >
      {{ __('Lock to current projects') }}
      <template #help>
        {{ s__('Runners|Use the runner for the currently assigned projects only.') }}
      </template>
    </gl-form-checkbox>

    <gl-form-group :label="__('IP Address')" data-testid="runner-field-ip-address">
      <gl-form-input-group :value="readonlyIpAddress" readonly select-on-click>
        <template #append>
          <gl-button
            v-gl-tooltip.hover
            :title="__('Copy IP Address')"
            :aria-label="__('Copy IP Address')"
            :data-clipboard-text="readonlyIpAddress"
            icon="copy-to-clipboard"
            class="d-inline-flex"
          />
        </template>
      </gl-form-input-group>
    </gl-form-group>

    <gl-form-group :label="__('Description')" data-testid="runner-field-description">
      <gl-form-input-group v-model="model.description" />
    </gl-form-group>

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
        __('You can set up jobs to only use runners with specific tags. Separate tags with commas.')
      "
    >
      <gl-form-input-group v-model="model.tagList" />
    </gl-form-group>

    <runner-update-cost-factor-fields v-model="model" />

    <div class="form-actions">
      <gl-button
        type="submit"
        variant="confirm"
        class="js-no-auto-disable"
        :loading="saving || !runner"
      >
        {{ __('Save changes') }}
      </gl-button>
    </div>
  </gl-form>
</template>
