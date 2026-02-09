<script>
import { GlButton } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { TYPENAME_CI_BUILD, TYPENAME_COMMIT_STATUS } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { JOB_GRAPHQL_ERRORS } from '~/ci/constants';
import { visitUrl } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import { reportToSentry } from '~/ci/utils';
import { confirmJobConfirmationMessage } from '~/ci/pipeline_details/graph/utils';
import PipelineInputsForm from '~/ci/common/pipeline_inputs/pipeline_inputs_form.vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import playJobWithVariablesMutation from '../graphql/mutations/job_play_with_variables.mutation.graphql';
import playJobWithInputsMutation from '../graphql/mutations/job_play_with_inputs.mutation.graphql';
import retryJobWithVariablesMutation from '../graphql/mutations/job_retry_with_variables.mutation.graphql';
import getJobInputsQuery from '../graphql/queries/get_job_inputs.query.graphql';
import JobVariablesForm from './job_variables_form.vue';

// This component is a port of ~/ci/job_details/components/legacy_manual_variables_form.vue
// It is meant to fetch/update the job information via GraphQL instead of REST API.

export default {
  name: 'JobRunForm',
  components: {
    GlButton,
    JobVariablesForm,
    PipelineInputsForm,
  },
  mixins: [glFeatureFlagMixin()],
  inject: ['canSetPipelineVariables', 'projectPath'],
  props: {
    isRetryable: {
      type: Boolean,
      required: true,
    },
    jobId: {
      type: Number,
      required: true,
    },
    jobName: {
      type: String,
      required: true,
    },
    confirmationMessage: {
      type: String,
      required: false,
      default: null,
    },
  },
  apollo: {
    job: {
      query: getJobInputsQuery,
      variables() {
        return {
          fullPath: this.projectPath,
          id: convertToGraphQLId(TYPENAME_COMMIT_STATUS, this.jobId),
        };
      },
      skip() {
        return !this.glFeatures.ciJobInputs;
      },
      update(data) {
        const job = data?.project?.job;
        return job || { inputs: [], inputsSpec: [] };
      },
      error() {
        createAlert({ message: JOB_GRAPHQL_ERRORS.jobInputsQueryErrorText });
      },
    },
  },
  emits: ['hide-manual-variables-form'],
  data() {
    return {
      runBtnDisabled: false,
      preparedVariables: [],
      updatedInputs: [],
      job: {},
    };
  },
  i18n: {
    cancel: s__('CiVariables|Cancel'),
    runAgainButtonText: s__('CiVariables|Run job again'),
    runButtonText: s__('CiVariables|Run job'),
  },
  computed: {
    mutationVariables() {
      return {
        id: convertToGraphQLId(TYPENAME_CI_BUILD, this.jobId),
        variables: this.preparedVariables,
      };
    },
    runBtnText() {
      return this.isRetryable
        ? this.$options.i18n.runAgainButtonText
        : this.$options.i18n.runButtonText;
    },
    showInputsForm() {
      return this.glFeatures.ciJobInputs && !this.$apollo.queries.job.loading;
    },
    playProps() {
      if (this.glFeatures.ciJobInputs) {
        return {
          mutation: playJobWithInputsMutation,
          variables: { ...this.mutationVariables, inputs: this.updatedInputs },
        };
      }
      return {
        mutation: playJobWithVariablesMutation,
        variables: this.mutationVariables,
      };
    },
  },
  methods: {
    onVariablesUpdate(variables) {
      this.preparedVariables = variables
        .filter((variable) => variable.key !== '')
        .map(({ key, value }) => ({ key, value }));
    },
    async playJob() {
      const { mutation, variables } = this.playProps;
      try {
        const { data } = await this.$apollo.mutate({
          mutation,
          variables,
        });
        if (data.jobPlay?.errors?.length) {
          createAlert({ message: data.jobPlay.errors[0] });
        } else {
          this.navigateToJob(data.jobPlay?.job?.webPath);
        }
      } catch (error) {
        createAlert({ message: JOB_GRAPHQL_ERRORS.jobMutationErrorText });
        reportToSentry(this.$options.name, error);
      }
    },
    async retryJob() {
      try {
        const { data } = await this.$apollo.mutate({
          mutation: retryJobWithVariablesMutation,
          variables: { ...this.mutationVariables, inputs: this.updatedInputs },
        });
        if (data.jobRetry?.errors?.length) {
          createAlert({ message: data.jobRetry.errors[0] });
        } else {
          this.navigateToJob(data.jobRetry?.job?.webPath);
        }
      } catch (error) {
        createAlert({ message: JOB_GRAPHQL_ERRORS.jobMutationErrorText });
        reportToSentry(this.$options.name, error);
      }
    },
    navigateToJob(path) {
      visitUrl(path);
    },
    async runJob() {
      this.runBtnDisabled = true;
      if (this.confirmationMessage !== null) {
        const confirmed = await confirmJobConfirmationMessage(
          this.jobName,
          this.confirmationMessage,
        );

        if (!confirmed) {
          this.runBtnDisabled = false;
          return;
        }
      }

      if (this.isRetryable) {
        this.retryJob();
      } else {
        this.playJob();
      }
    },
    handleInputsUpdated(updatedInputs) {
      this.updatedInputs = updatedInputs;
    },
  },
};
</script>
<template>
  <div>
    <pipeline-inputs-form
      v-if="showInputsForm"
      emit-modified-only
      preselect-all-inputs
      :saved-inputs="job.inputs"
      :initial-inputs="job.inputsSpec"
      :empty-selection-text="s__('Pipeline|Select inputs to create a new pipeline.')"
      @update-inputs="handleInputsUpdated"
    />

    <job-variables-form
      v-if="canSetPipelineVariables"
      :job-id="jobId"
      :is-expanded="!glFeatures.ciJobInputs"
      @update-variables="onVariablesUpdate"
    />

    <div class="gl-mt-5 gl-flex gl-gap-x-4">
      <gl-button
        variant="confirm"
        category="primary"
        :disabled="runBtnDisabled"
        data-testid="run-manual-job-btn"
        @click="runJob"
      >
        {{ runBtnText }}
      </gl-button>
      <gl-button
        v-if="isRetryable"
        data-testid="cancel-btn"
        @click="$emit('hide-manual-variables-form')"
        >{{ $options.i18n.cancel }}
      </gl-button>
    </div>
  </div>
</template>
