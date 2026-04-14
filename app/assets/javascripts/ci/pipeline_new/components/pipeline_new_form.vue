<script>
import { GlAlert, GlButton, GlLink, GlForm, GlFormGroup, GlSprintf } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { visitUrl, joinPaths, getParameterByName } from '~/lib/utils/url_utility';
import { s__, __, n__ } from '~/locale';
import { createAlert } from '~/alert';
import SafeHtml from '~/vue_shared/directives/safe_html';
import PipelineInputsForm from '~/ci/common/pipeline_inputs/pipeline_inputs_form.vue';
import createPipelineMutation from '../graphql/mutations/create_pipeline.mutation.graphql';
import getRelatedMergeRequest from '../graphql/queries/related_merge_request.query.graphql';
import RefsDropdown from './refs_dropdown.vue';
import PipelineVariablesForm from './pipeline_variables_form.vue';

const i18n = {
  configButtonTitle: s__('Pipelines|Go to the pipeline editor'),
  defaultError: __('Something went wrong on our end. Please try again.'),
  maxWarningsSummary: __('%{total} warnings found: showing first %{warningsDisplayed}'),
  refsLoadingErrorTitle: s__('Pipeline|Branches or tags could not be loaded.'),
  submitErrorTitle: s__('Pipeline|Pipeline cannot be run.'),
  warningTitle: __('The form contains the following warning:'),
  mrPipelineDescription: s__(
    'Pipeline|You are creating a pipeline for merge request %{mergeRequestLink}. The pipeline will run on the merge request source branch.',
  ),
};

export default {
  name: 'PipelineNewForm',
  i18n,
  ROLE_MAINTAINER: 'maintainer',
  components: {
    GlAlert,
    GlButton,
    GlLink,
    GlForm,
    GlFormGroup,
    GlSprintf,
    PipelineInputsForm,
    PipelineVariablesForm,
    RefsDropdown,
    PipelineAccountVerificationAlert: () =>
      import('ee_component/vue_shared/components/pipeline_account_verification_alert.vue'),
  },
  directives: { SafeHtml },
  inject: [
    'canViewPipelineEditor',
    'canSetPipelineVariables',
    'pipelineEditorPath',
    'pipelinesPath',
    'projectPath',
    'userRole',
  ],
  props: {
    defaultBranch: {
      type: String,
      required: true,
    },
    projectId: {
      type: String,
      required: true,
    },
    settingsLink: {
      type: String,
      required: true,
    },
    fileParams: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    refParam: {
      type: String,
      required: false,
      default: '',
    },
    variableParams: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    maxWarnings: {
      type: Number,
      required: true,
    },
  },
  apollo: {
    relatedMergeRequest: {
      query: getRelatedMergeRequest,
      variables() {
        return {
          fullPath: this.projectPath,
          iid: this.mergeRequestIid,
        };
      },
      skip() {
        return !this.mergeRequestIid;
      },
      update(data) {
        const mergeRequest = data?.project?.mergeRequest;
        if (mergeRequest?.sourceBranch) {
          this.refValue = { shortName: mergeRequest.sourceBranch };
        }
        return mergeRequest;
      },
      error() {
        createAlert({
          message: s__('Pipelines|An error occurred while fetching the merge request details.'),
        });
      },
    },
  },
  data() {
    return {
      refValue: {
        shortName: this.refParam,
        // this is needed until we add support for ref type in url query strings
        // ensure default branch is called with full ref on load
        // https://gitlab.com/gitlab-org/gitlab/-/issues/287815
        fullName: this.refParam === this.defaultBranch ? `refs/heads/${this.refParam}` : undefined,
      },
      errorTitle: null,
      error: null,
      pipelineInputs: [],
      pipelineVariables: [],
      warnings: [],
      totalWarnings: 0,
      isWarningDismissed: false,
      submitted: false,
      isSubmitDisabled: false,
      relatedMergeRequest: null,
    };
  },
  computed: {
    identityVerificationRequiredError() {
      return this.error === __('Identity verification is required in order to run CI jobs');
    },
    isMaintainer() {
      return this.userRole?.toLowerCase() === this.$options.ROLE_MAINTAINER;
    },
    overMaxWarningsLimit() {
      return this.totalWarnings > this.maxWarnings;
    },
    refFullName() {
      return this.refValue.fullName;
    },
    refShortName() {
      return this.refValue.shortName;
    },
    refQueryParam() {
      return this.refFullName || this.refShortName;
    },

    shouldShowWarning() {
      return this.warnings.length > 0 && !this.isWarningDismissed;
    },
    summaryMessage() {
      return this.overMaxWarningsLimit ? i18n.maxWarningsSummary : this.warningsSummary;
    },
    warningsSummary() {
      return n__('%d warning found:', '%d warnings found:', this.warnings.length);
    },
    mergeRequestIid() {
      const iid = getParameterByName('merge_request_iid');
      return iid && /^\d+$/.test(iid) ? iid : null;
    },
    relatedMergeRequestLoading() {
      return this.$apollo.queries.relatedMergeRequest?.loading;
    },
    mergeRequestPipelinesPath() {
      return joinPaths(this.relatedMergeRequest.webPath, 'pipelines');
    },
    cancelPath() {
      return this.relatedMergeRequest ? this.mergeRequestPipelinesPath : this.pipelinesPath;
    },
    createPipelineInput() {
      const baseInput = {
        projectPath: this.projectPath,
        ref: this.refShortName,
        variables: this.pipelineVariables,
        inputs: this.pipelineInputs,
      };
      return this.relatedMergeRequest
        ? { ...baseInput, mergeRequestIid: this.mergeRequestIid }
        : baseInput;
    },
  },
  methods: {
    handleValidityChange(isFormValid) {
      this.isSubmitDisabled = !isFormValid;
    },
    async createPipeline() {
      this.submitted = true;
      try {
        const {
          data: {
            pipelineCreate: { errors, pipeline },
          },
        } = await this.$apollo.mutate({
          mutation: createPipelineMutation,
          variables: {
            input: this.createPipelineInput,
          },
        });

        const pipelineErrors = pipeline?.errorMessages?.nodes?.map((node) => node?.content) || '';
        const totalWarnings = pipeline?.warningMessages?.nodes?.length || 0;

        if (pipeline?.path) {
          const nextUrl = this.relatedMergeRequest ? this.mergeRequestPipelinesPath : pipeline.path;
          visitUrl(nextUrl);
        } else if (errors?.length > 0 || pipelineErrors.length || totalWarnings) {
          const warnings = pipeline?.warningMessages?.nodes?.map((node) => node?.content) || '';
          const error = errors[0] || pipelineErrors[0] || '';

          this.reportError({
            title: i18n.submitErrorTitle,
            error,
            warnings,
            totalWarnings,
          });
        }
      } catch (error) {
        createAlert({ message: i18n.submitErrorTitle });
        Sentry.captureException(error);
      }

      // always re-enable submit button
      this.submitted = false;
    },
    handleInputsUpdated(updatedInputs) {
      this.pipelineInputs = updatedInputs;
    },
    handleVariablesUpdated(updatedVariables) {
      this.pipelineVariables = updatedVariables;
    },
    onRefsLoadingError(error) {
      this.reportError({ title: i18n.refsLoadingErrorTitle });

      Sentry.captureException(error);
    },
    reportError({ title = null, error = i18n.defaultError, warnings = [], totalWarnings = 0 }) {
      this.errorTitle = title;
      this.error = error;
      this.warnings = warnings;
      this.totalWarnings = totalWarnings;
    },
  },
};
</script>

<template>
  <gl-form @submit.prevent="createPipeline">
    <pipeline-account-verification-alert v-if="identityVerificationRequiredError" class="gl-mb-4" />
    <gl-alert
      v-else-if="error"
      :title="errorTitle"
      :dismissible="false"
      variant="danger"
      class="gl-mb-4"
    >
      <span v-safe-html="error" data-testid="run-pipeline-error-alert" class="block"></span>
      <gl-button
        v-if="canViewPipelineEditor"
        class="gl-my-3"
        data-testid="ci-cd-pipeline-configuration"
        variant="confirm"
        :aria-label="$options.i18n.configButtonTitle"
        :href="pipelineEditorPath"
      >
        {{ $options.i18n.configButtonTitle }}
      </gl-button>
    </gl-alert>
    <gl-alert
      v-if="shouldShowWarning"
      :title="$options.i18n.warningTitle"
      variant="warning"
      class="gl-mb-4"
      data-testid="run-pipeline-warning-alert"
      @dismiss="isWarningDismissed = true"
    >
      <details>
        <summary>
          <gl-sprintf :message="summaryMessage">
            <template #total>
              {{ totalWarnings }}
            </template>
            <template #warningsDisplayed>
              {{ maxWarnings }}
            </template>
          </gl-sprintf>
        </summary>
        <p
          v-for="(warning, index) in warnings"
          :key="`warning-${index}`"
          data-testid="run-pipeline-warning"
        >
          {{ warning }}
        </p>
      </details>
    </gl-alert>
    <gl-alert
      v-if="relatedMergeRequest"
      variant="info"
      :dismissible="false"
      class="gl-mb-4"
      data-testid="mr-pipeline-info-alert"
    >
      <gl-sprintf :message="$options.i18n.mrPipelineDescription">
        <template #mergeRequestLink>
          <gl-link :href="relatedMergeRequest.webPath" data-testid="mr-link"
            >!{{ mergeRequestIid }}</gl-link
          >
        </template>
      </gl-sprintf>
    </gl-alert>
    <div v-if="!relatedMergeRequestLoading" class="gl-flex gl-flex-col gl-gap-5">
      <gl-form-group
        id="pipeline-ref-label"
        :label="s__('Pipeline|Run for branch name or tag')"
        class="gl-mb-0"
      >
        <refs-dropdown
          v-model="refValue"
          :project-id="projectId"
          toggle-aria-labelled-by="pipeline-ref-label"
          @loadingError="onRefsLoadingError"
        />
      </gl-form-group>
      <pipeline-inputs-form
        emit-modified-only
        preselect-all-inputs
        :project-path="projectPath"
        :query-ref="refQueryParam"
        :empty-selection-text="s__('Pipeline|Select inputs to create a new pipeline.')"
        @update-inputs="handleInputsUpdated"
      />
      <pipeline-variables-form
        v-if="canSetPipelineVariables"
        :file-params="fileParams"
        :is-maintainer="isMaintainer"
        :project-path="projectPath"
        :ref-param="refQueryParam"
        :settings-link="settingsLink"
        :variable-params="variableParams"
        @variables-updated="handleVariablesUpdated"
        @validity-change="handleValidityChange"
      />

      <div class="gl-flex">
        <gl-button
          type="submit"
          category="primary"
          variant="confirm"
          class="js-no-auto-disable gl-mr-3"
          data-testid="run-pipeline-button"
          :disabled="submitted || isSubmitDisabled"
          >{{ s__('Pipeline|New pipeline') }}</gl-button
        >
        <gl-button :href="cancelPath" data-testid="cancel-button">{{ __('Cancel') }}</gl-button>
      </div>
    </div>
  </gl-form>
</template>
