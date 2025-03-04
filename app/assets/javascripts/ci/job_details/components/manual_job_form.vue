<script>
import { GlButton } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { TYPENAME_CI_BUILD } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { JOB_GRAPHQL_ERRORS } from '~/ci/constants';
import { visitUrl } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import { reportToSentry } from '~/ci/utils';
import { confirmJobConfirmationMessage } from '~/ci/pipeline_details/graph/utils';
import playJobWithVariablesMutation from '../graphql/mutations/job_play_with_variables.mutation.graphql';
import retryJobWithVariablesMutation from '../graphql/mutations/job_retry_with_variables.mutation.graphql';
import JobVariablesForm from './job_variables_form.vue';

// This component is a port of ~/ci/job_details/components/legacy_manual_variables_form.vue
// It is meant to fetch/update the job information via GraphQL instead of REST API.

export default {
  name: 'ManualJobForm',
  components: {
    GlButton,
    JobVariablesForm,
  },
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
    canViewPipelineVariables: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      runBtnDisabled: false,
      preparedVariables: [],
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
  },
  methods: {
    onVariablesUpdate(variables) {
      this.preparedVariables = variables
        .filter((variable) => variable.key !== '')
        .map(({ key, value }) => ({ key, value }));
    },
    async playJob() {
      try {
        const { data } = await this.$apollo.mutate({
          mutation: playJobWithVariablesMutation,
          variables: this.mutationVariables,
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
          variables: this.mutationVariables,
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
  },
};
</script>
<template>
  <div>
    <job-variables-form
      v-if="canViewPipelineVariables"
      :job-id="jobId"
      @update-variables="onVariablesUpdate"
    />

    <div class="gl-mt-5 gl-flex gl-justify-center gl-gap-x-2">
      <gl-button
        v-if="isRetryable"
        data-testid="cancel-btn"
        @click="$emit('hideManualVariablesForm')"
        >{{ $options.i18n.cancel }}
      </gl-button>
      <gl-button
        variant="confirm"
        category="primary"
        :disabled="runBtnDisabled"
        data-testid="run-manual-job-btn"
        @click="runJob"
      >
        {{ runBtnText }}
      </gl-button>
    </div>
  </div>
</template>
