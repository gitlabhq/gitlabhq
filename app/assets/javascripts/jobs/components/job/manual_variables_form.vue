<script>
import {
  GlFormInputGroup,
  GlInputGroupText,
  GlFormInput,
  GlButton,
  GlLink,
  GlLoadingIcon,
  GlSprintf,
  GlTooltipDirective,
} from '@gitlab/ui';
import { cloneDeep, uniqueId } from 'lodash';
import { mapActions } from 'vuex';
import { fetchPolicies } from '~/lib/graphql';
import { createAlert } from '~/flash';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { JOB_GRAPHQL_ERRORS, GRAPHQL_ID_TYPES } from '~/jobs/constants';
import { helpPagePath } from '~/helpers/help_page_helper';
import { redirectTo } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import GetJob from './graphql/queries/get_job.query.graphql';
import retryJobWithVariablesMutation from './graphql/mutations/job_retry_with_variables.mutation.graphql';

// This component is a port of ~/jobs/components/job/legacy_manual_variables_form.vue
// It is meant to fetch/update the job information via GraphQL instead of REST API.

export default {
  name: 'ManualVariablesForm',
  components: {
    GlFormInputGroup,
    GlInputGroupText,
    GlFormInput,
    GlButton,
    GlLink,
    GlLoadingIcon,
    GlSprintf,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['projectPath'],
  apollo: {
    variables: {
      query: GetJob,
      variables() {
        return {
          fullPath: this.projectPath,
          id: convertToGraphQLId(GRAPHQL_ID_TYPES.commitStatus, this.jobId),
        };
      },
      fetchPolicy: fetchPolicies.CACHE_AND_NETWORK,
      update(data) {
        const jobVariables = cloneDeep(data?.project?.job?.manualVariables?.nodes);
        return [...jobVariables.reverse(), ...this.variables];
      },
      error() {
        createAlert({ message: JOB_GRAPHQL_ERRORS.jobQueryErrorText });
      },
    },
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
  },
  inputTypes: {
    key: 'key',
    value: 'value',
  },
  i18n: {
    clearInputs: s__('CiVariables|Clear inputs'),
    formHelpText: s__(
      'CiVariables|Specify variable values to be used in this run. The values specified in %{linkStart}CI/CD settings%{linkEnd} will be used as default',
    ),
    header: s__('CiVariables|Variables'),
    keyLabel: s__('CiVariables|Key'),
    keyPlaceholder: s__('CiVariables|Input variable key'),
    runAgainButtonText: s__('CiVariables|Run job again'),
    triggerButtonText: s__('CiVariables|Trigger this manual action'),
    valueLabel: s__('CiVariables|Value'),
    valuePlaceholder: s__('CiVariables|Input variable value'),
  },
  variableValueKeys: {
    rest: 'secret_value',
    gql: 'value',
  },
  data() {
    return {
      job: {},
      variables: [
        {
          id: uniqueId(),
          key: '',
          value: '',
        },
      ],
      runAgainBtnDisabled: false,
      triggerBtnDisabled: false,
    };
  },
  computed: {
    preparedVariables() {
      // filtering out 'id' along with empty variables to send only key, value in the mutation.
      // This will be removed in: https://gitlab.com/gitlab-org/gitlab/-/issues/377268

      return this.variables
        .filter((variable) => variable.key !== '')
        .map(({ key, value }) => ({ key, [this.valueKey]: value }));
    },
    valueKey() {
      return this.isRetryable
        ? this.$options.variableValueKeys.gql
        : this.$options.variableValueKeys.rest;
    },
    variableSettings() {
      return helpPagePath('ci/variables/index', { anchor: 'add-a-cicd-variable-to-a-project' });
    },
  },
  methods: {
    ...mapActions(['triggerManualJob']),
    addEmptyVariable() {
      const lastVar = this.variables[this.variables.length - 1];

      if (lastVar.key === '') {
        return;
      }

      this.variables.push({
        id: uniqueId(),
        key: '',
        value: '',
      });
    },
    canRemove(index) {
      return index < this.variables.length - 1;
    },
    deleteVariable(id) {
      this.variables.splice(
        this.variables.findIndex((el) => el.id === id),
        1,
      );
    },
    inputRef(type, id) {
      return `${this.$options.inputTypes[type]}-${id}`;
    },
    navigateToRetriedJob(retryPath) {
      redirectTo(retryPath);
    },
    async retryJob() {
      try {
        const { data } = await this.$apollo.mutate({
          mutation: retryJobWithVariablesMutation,
          variables: {
            id: convertToGraphQLId(GRAPHQL_ID_TYPES.ciBuild, this.jobId),
            // we need to ensure no empty variables are passed to the API
            variables: this.preparedVariables,
          },
        });
        if (data.jobRetry?.errors?.length) {
          createAlert({ message: data.jobRetry.errors[0] });
        } else {
          this.navigateToRetriedJob(data.jobRetry?.job?.webPath);
        }
      } catch (error) {
        createAlert({ message: JOB_GRAPHQL_ERRORS.retryMutationErrorText });
      }
    },
    runAgain() {
      this.runAgainBtnDisabled = true;

      this.retryJob();
    },
    triggerJob() {
      this.triggerBtnDisabled = true;

      this.triggerManualJob(this.preparedVariables);
    },
  },
};
</script>
<template>
  <gl-loading-icon v-if="$apollo.queries.variables.loading" class="gl-mt-9" size="lg" />
  <div v-else class="row gl-justify-content-center">
    <div class="col-10" data-testid="manual-vars-form">
      <label>{{ $options.i18n.header }}</label>

      <div
        v-for="(variable, index) in variables"
        :key="variable.id"
        class="gl-display-flex gl-align-items-center gl-mb-4"
        data-testid="ci-variable-row"
      >
        <gl-form-input-group class="gl-mr-4 gl-flex-grow-1">
          <template #prepend>
            <gl-input-group-text>
              {{ $options.i18n.keyLabel }}
            </gl-input-group-text>
          </template>
          <gl-form-input
            :ref="inputRef('key', variable.id)"
            v-model="variable.key"
            :placeholder="$options.i18n.keyPlaceholder"
            data-testid="ci-variable-key"
            @change="addEmptyVariable"
          />
        </gl-form-input-group>

        <gl-form-input-group class="gl-flex-grow-2">
          <template #prepend>
            <gl-input-group-text>
              {{ $options.i18n.valueLabel }}
            </gl-input-group-text>
          </template>
          <gl-form-input
            :ref="inputRef('value', variable.id)"
            v-model="variable.value"
            :placeholder="$options.i18n.valuePlaceholder"
            data-testid="ci-variable-value"
          />
        </gl-form-input-group>

        <gl-button
          v-if="canRemove(index)"
          v-gl-tooltip
          :aria-label="$options.i18n.clearInputs"
          :title="$options.i18n.clearInputs"
          class="gl-flex-grow-0 gl-flex-basis-0"
          category="tertiary"
          variant="danger"
          icon="clear"
          data-testid="delete-variable-btn"
          @click="deleteVariable(variable.id)"
        />

        <!-- delete variable button placeholder to not break flex layout  -->
        <div v-else class="gl-w-7 gl-mr-3" data-testid="delete-variable-btn-placeholder"></div>
      </div>

      <div class="gl-text-center gl-mt-5">
        <gl-sprintf :message="$options.i18n.formHelpText">
          <template #link="{ content }">
            <gl-link :href="variableSettings" target="_blank">
              {{ content }}
            </gl-link>
          </template>
        </gl-sprintf>
      </div>
      <div v-if="isRetryable" class="gl-display-flex gl-justify-content-center gl-mt-5">
        <gl-button
          class="gl-mt-5"
          :aria-label="__('Cancel')"
          data-testid="cancel-btn"
          @click="$emit('hideManualVariablesForm')"
          >{{ __('Cancel') }}</gl-button
        >
        <gl-button
          class="gl-mt-5"
          variant="confirm"
          category="primary"
          :aria-label="__('Run manual job again')"
          :disabled="runAgainBtnDisabled"
          data-testid="run-manual-job-btn"
          @click="runAgain"
        >
          {{ $options.i18n.runAgainButtonText }}
        </gl-button>
      </div>
      <div v-else class="gl-display-flex gl-justify-content-center gl-mt-5">
        <gl-button
          class="gl-mt-5"
          variant="confirm"
          category="primary"
          :aria-label="__('Trigger manual job')"
          :disabled="triggerBtnDisabled"
          data-testid="trigger-manual-job-btn"
          @click="triggerJob"
        >
          {{ $options.i18n.triggerButtonText }}
        </gl-button>
      </div>
    </div>
  </div>
</template>
