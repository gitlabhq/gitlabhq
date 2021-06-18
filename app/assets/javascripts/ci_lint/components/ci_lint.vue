<script>
import { GlButton, GlFormCheckbox, GlIcon, GlLink, GlAlert } from '@gitlab/ui';
import CiLintResults from '~/pipeline_editor/components/lint/ci_lint_results.vue';
import lintCiMutation from '~/pipeline_editor/graphql/mutations/lint_ci.mutation.graphql';
import SourceEditor from '~/vue_shared/components/source_editor.vue';

export default {
  components: {
    GlButton,
    GlFormCheckbox,
    GlIcon,
    GlLink,
    GlAlert,
    CiLintResults,
    SourceEditor,
  },
  props: {
    endpoint: {
      type: String,
      required: true,
    },
    lintHelpPagePath: {
      type: String,
      required: true,
    },
    pipelineSimulationHelpPagePath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      content: '',
      loading: false,
      isValid: false,
      errors: null,
      warnings: null,
      jobs: [],
      dryRun: false,
      showingResults: false,
      apiError: null,
      isErrorDismissed: false,
    };
  },
  computed: {
    shouldShowError() {
      return this.apiError && !this.isErrorDismissed;
    },
  },
  methods: {
    async lint() {
      this.loading = true;
      try {
        const {
          data: {
            lintCI: { valid, errors, warnings, jobs },
          },
        } = await this.$apollo.mutate({
          mutation: lintCiMutation,
          variables: { endpoint: this.endpoint, content: this.content, dry: this.dryRun },
        });

        this.showingResults = true;
        this.isValid = valid;
        this.errors = errors;
        this.warnings = warnings;
        this.jobs = jobs;
      } catch (error) {
        this.apiError = error;
        this.isErrorDismissed = false;
      } finally {
        this.loading = false;
      }
    },
    clear() {
      this.content = '';
    },
  },
};
</script>

<template>
  <div class="row">
    <div class="col-sm-12">
      <gl-alert
        v-if="shouldShowError"
        class="gl-mb-3"
        variant="danger"
        @dismiss="isErrorDismissed = true"
        >{{ apiError }}</gl-alert
      >
      <div class="file-holder gl-mb-3">
        <div class="js-file-title file-title clearfix">
          {{ __('Contents of .gitlab-ci.yml') }}
        </div>
        <source-editor v-model="content" file-name="*.yml" />
      </div>
    </div>

    <div class="col-sm-12 gl-display-flex gl-justify-content-space-between">
      <div class="gl-display-flex gl-align-items-center">
        <gl-button
          class="gl-mr-4"
          :loading="loading"
          category="primary"
          variant="success"
          data-testid="ci-lint-validate"
          @click="lint"
          >{{ __('Validate') }}</gl-button
        >
        <gl-form-checkbox v-model="dryRun"
          >{{ __('Simulate a pipeline created for the default branch') }}
          <gl-link :href="pipelineSimulationHelpPagePath" target="_blank"
            ><gl-icon class="gl-text-blue-600" name="question-o" /></gl-link
        ></gl-form-checkbox>
      </div>
      <gl-button data-testid="ci-lint-clear" @click="clear">{{ __('Clear') }}</gl-button>
    </div>

    <ci-lint-results
      v-if="showingResults"
      class="col-sm-12 gl-mt-5"
      :is-valid="isValid"
      :jobs="jobs"
      :errors="errors"
      :warnings="warnings"
      :dry-run="dryRun"
      :lint-help-page-path="lintHelpPagePath"
    />
  </div>
</template>
