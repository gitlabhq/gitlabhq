<script>
import { GlForm, GlButton, GlFormGroup, GlFormInput, GlFormTextarea } from '@gitlab/ui';
import { createAlert } from '~/alert';
import MultiStepFormTemplate from '~/vue_shared/components/multi_step_form_template.vue';
import MultipleChoiceSelector from '~/vue_shared/components/multiple_choice_selector.vue';
import MultipleChoiceSelectorItem from '~/vue_shared/components/multiple_choice_selector_item.vue';
import runnerCreateMutation from '~/ci/runner/graphql/new/runner_create.mutation.graphql';
import { modelToUpdateMutationVariables } from 'ee_else_ce/ci/runner/runner_update_form_utils';
import { captureException } from '../sentry_utils';
import {
  DEFAULT_ACCESS_LEVEL,
  ACCESS_LEVEL_NOT_PROTECTED,
  ACCESS_LEVEL_REF_PROTECTED,
  GROUP_TYPE,
  PROJECT_TYPE,
  I18N_CREATE_ERROR,
} from '../constants';

export default {
  components: {
    GlForm,
    GlButton,
    GlFormGroup,
    GlFormInput,
    GlFormTextarea,
    MultiStepFormTemplate,
    MultipleChoiceSelector,
    MultipleChoiceSelectorItem,
  },
  props: {
    currentStep: {
      type: Number,
      required: true,
    },
    stepsTotal: {
      type: Number,
      required: true,
    },
    tags: {
      type: String,
      required: true,
    },
    runUntagged: {
      type: Boolean,
      required: true,
    },
    runnerType: {
      type: String,
      required: true,
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
        runUntagged: this.runUntagged,
        locked: false,
        tagList: this.tags,
        maximumTimeout: null,
      },
      saving: false,
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
    onCheckboxesInput(checked) {
      if (checked.includes(ACCESS_LEVEL_REF_PROTECTED))
        this.runner.accessLevel = ACCESS_LEVEL_REF_PROTECTED;
      else this.runner.accessLevel = ACCESS_LEVEL_NOT_PROTECTED;

      this.runner.paused = checked.includes('paused');
    },
    async onSubmit() {
      this.saving = true;
      this.runner.maximumTimeout = parseInt(this.runner.maximumTimeout, 10);

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

        this.$emit('onGetNewRunnerId', runner.id);
        this.$emit('next');
        // destroy the alert
        createAlert({ message: null }).dismiss();
      } catch (error) {
        this.onError(error);
      }
    },
    onError(error, isValidationError = false) {
      if (!isValidationError) {
        captureException({ error, component: this.$options.name });
      }

      createAlert({ message: error.message });
      this.saving = false;
    },
  },
  ACCESS_LEVEL_REF_PROTECTED,
};
</script>
<template>
  <gl-form @submit.prevent="onSubmit">
    <multi-step-form-template
      :title="s__('Runners|Optional configuration details')"
      :current-step="currentStep"
      :steps-total="stepsTotal"
    >
      <template #form>
        <multiple-choice-selector class="gl-mb-5" @input="onCheckboxesInput">
          <multiple-choice-selector-item
            :value="$options.ACCESS_LEVEL_REF_PROTECTED"
            :title="s__('Runners|Protected')"
            :description="s__('Runners|Use the runner on pipelines for protected branches only.')"
          />
          <multiple-choice-selector-item
            value="paused"
            :title="s__('Runners|Paused')"
            :description="s__('Runners|Stop the runner from accepting new jobs.')"
          />
        </multiple-choice-selector>

        <gl-form-group
          label-for="runner-description"
          :label="s__('Runners|Runner description')"
          :optional="true"
        >
          <gl-form-input
            id="runner-description"
            v-model="runner.description"
            name="description"
            data-testid="runner-description-input"
          />
        </gl-form-group>

        <gl-form-group
          label-for="runner-maintenance-note"
          :label="s__('Runners|Maintenance note')"
          :label-description="
            s__('Runners|Add notes such as the runner owner or what it should be used for.')
          "
          :optional="true"
          :description="s__('Runners|Only administrators can view this.')"
        >
          <gl-form-textarea
            id="runner-maintenance-note"
            v-model="runner.maintenanceNote"
            name="maintenance-note"
            data-testid="runner-maintenance-note"
          />
        </gl-form-group>

        <gl-form-group
          label-for="max-timeout"
          :label="s__('Runners|Maximum job timeout')"
          :label-description="
            s__(
              'Runners|Maximum amount of time the runner can run before it terminates. If a project has a shorter job timeout period, the job timeout period of the instance runner is used instead.',
            )
          "
          :optional="true"
          :description="
            s__('Runners|Enter the job timeout in seconds. Must be a minimum of 600 seconds.')
          "
        >
          <gl-form-input
            id="max-timeout"
            v-model="runner.maximumTimeout"
            name="max-timeout"
            type="number"
            data-testid="max-timeout-input"
          />
        </gl-form-group>
      </template>
      <template #next>
        <gl-button
          category="primary"
          variant="confirm"
          type="submit"
          class="js-no-auto-disable"
          :loading="saving"
          data-testid="next-button"
        >
          {{ __('Next step') }}
        </gl-button>
      </template>
      <template #back>
        <gl-button
          category="primary"
          variant="default"
          data-testid="back-button"
          @click="$emit('back')"
        >
          {{ __('Go back') }}
        </gl-button>
      </template>
    </multi-step-form-template>
  </gl-form>
</template>
