<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import { reportToSentry } from '~/ci/utils';
import { fetchPolicies } from '~/lib/graphql';
import { createAlert } from '~/alert';
import filterVariables from '../utils/filter_variables';
import {
  CI_VARIABLE_TYPE_FILE,
  CI_VARIABLE_TYPE_ENV_VAR,
  CI_VARIABLES_POLLING_INTERVAL,
  CI_VARIABLES_MAX_POLLING_TIME,
} from '../constants';
import ciConfigVariablesQuery from '../graphql/queries/ci_config_variables.graphql';
import VariablesForm from '../../common/variables_form.vue';

export default {
  name: 'PipelineVariablesForm',
  learnMorePath: helpPagePath('ci/variables/_index', {
    anchor: 'cicd-variable-precedence',
  }),
  userCalloutsFeatureName: 'pipeline_new_inputs_adoption_banner',
  components: {
    GlLink,
    GlSprintf,
    VariablesForm,
  },
  inject: ['projectPath'],
  props: {
    fileParams: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    isMaintainer: {
      type: Boolean,
      required: true,
    },
    refParam: {
      type: String,
      required: true,
    },
    settingsLink: {
      type: String,
      required: true,
    },
    variableParams: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      ciConfigVariables: null,
      currentRefVariables: [],
      maxPollTimeout: null,
      pollingStartTime: null,
      manualPollInterval: null,
    };
  },
  computed: {
    isFetchingCiConfigVariables() {
      return this.ciConfigVariables === null;
    },
    isLoading() {
      return this.isFetchingCiConfigVariables;
    },
  },
  watch: {
    refParam() {
      this.ciConfigVariables = null;
      this.clearTimeouts();
      this.startManualPolling();
    },
  },
  mounted() {
    this.startManualPolling();
  },
  beforeDestroy() {
    this.clearTimeouts();
  },
  methods: {
    onVariablesUpdate(variables) {
      this.$emit('variables-updated', filterVariables(variables));
    },
    clearTimeouts() {
      if (this.maxPollTimeout) {
        clearTimeout(this.maxPollTimeout);
        this.maxPollTimeout = null;
      }
      if (this.manualPollInterval) {
        clearInterval(this.manualPollInterval);
        this.manualPollInterval = null;
      }
      this.pollingStartTime = null;
    },
    populateForm() {
      if (!this.ciConfigVariables) return;

      const variables = this.ciConfigVariables
        .filter(({ description }) => description)
        .map(({ key, value, description, valueOptions }) => ({
          uniqueId: uniqueId(`var-${this.refParam}`),
          key,
          value: value || '',
          variableType: CI_VARIABLE_TYPE_ENV_VAR,
          description,
          valueOptions,
          destroy: false,
        }));

      this.mergeParams(variables, CI_VARIABLE_TYPE_ENV_VAR, this.variableParams);
      this.mergeParams(variables, CI_VARIABLE_TYPE_FILE, this.fileParams);

      this.currentRefVariables = variables;
    },
    mergeParams(variables, type, paramsObj) {
      if (!paramsObj) return;

      Object.entries(paramsObj).forEach(([key, value]) => {
        const variable = variables.find((v) => v.key === key);

        if (variable) {
          variable.value = value;
          variable.variableType = type;
        } else {
          variables.push({
            uniqueId: uniqueId(`var-${this.refParam}`),
            key,
            value,
            variableType: type,
            destroy: false,
          });
        }
      });
    },
    stopPollingAndPopulateForm() {
      this.clearTimeouts();
      this.populateForm();
    },
    async executeQuery(failOnCacheMiss = false) {
      try {
        const result = await this.$apollo.query({
          query: ciConfigVariablesQuery,
          variables: {
            fullPath: this.projectPath,
            ref: this.refParam,
            failOnCacheMiss,
          },
          fetchPolicy: fetchPolicies.NO_CACHE,
        });

        this.ciConfigVariables = result.data?.project?.ciConfigVariables;

        if (this.ciConfigVariables) {
          this.stopPollingAndPopulateForm();
          return true;
        }

        return false;
      } catch (error) {
        this.handleQueryError(error);
        return true;
      }
    },
    handleQueryError(error) {
      reportToSentry(this.$options.name, error);
      createAlert({
        message: error.message || s__('Pipeline|Failed to retrieve CI/CD variables.'),
      });
      this.ciConfigVariables = [];
      this.stopPollingAndPopulateForm();
    },
    startManualPolling() {
      const CI_VARIABLES_FINAL_ATTEMPT_THRESHOLD =
        CI_VARIABLES_MAX_POLLING_TIME - CI_VARIABLES_POLLING_INTERVAL;
      this.pollingStartTime = Date.now();

      this.executeQuery(false);

      this.manualPollInterval = setInterval(async () => {
        const pollingDuration = Date.now() - this.pollingStartTime;
        const isLastAttempt = pollingDuration >= CI_VARIABLES_FINAL_ATTEMPT_THRESHOLD;

        const shouldStop = await this.executeQuery(isLastAttempt);

        if (shouldStop) {
          this.clearTimeouts();
        }
      }, CI_VARIABLES_POLLING_INTERVAL);

      this.maxPollTimeout = setTimeout(() => {
        this.ciConfigVariables = this.ciConfigVariables || [];
        this.stopPollingAndPopulateForm();
      }, CI_VARIABLES_MAX_POLLING_TIME);
    },
  },
};
</script>

<template>
  <variables-form
    :initial-variables="currentRefVariables"
    :is-loading="isLoading"
    :user-callouts-feature-name="$options.userCalloutsFeatureName"
    @update-variables="onVariablesUpdate"
  >
    <template #description>
      <gl-sprintf
        :message="
          s__(
            'Pipeline|Specify variable values to be used in this run. The variables specified in the configuration file as well as %{linkStart}CI/CD settings%{linkEnd} are used by default.',
          )
        "
      >
        <template #link="{ content }">
          <gl-link v-if="isMaintainer" :href="settingsLink" data-testid="ci-cd-settings-link">
            {{ content }}
          </gl-link>
          <template v-else>{{ content }}</template>
        </template>
      </gl-sprintf>
      <gl-link :href="$options.learnMorePath" target="_blank">
        {{ __('Learn more') }}
      </gl-link>
      <div class="gl-mt-4 gl-text-subtle">
        <gl-sprintf
          :message="
            s__(
              'CiVariables|Variables specified here are %{boldStart}expanded%{boldEnd} and not %{boldStart}masked.%{boldEnd}',
            )
          "
        >
          <template #bold="{ content }">
            <strong>{{ content }}</strong>
          </template>
        </gl-sprintf>
      </div>
    </template>
  </variables-form>
</template>
