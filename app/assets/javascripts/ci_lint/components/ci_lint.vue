<script>
import { GlButton, GlFormCheckbox, GlIcon, GlLink, GlAlert } from '@gitlab/ui';
import CiLintResults from './ci_lint_results.vue';
import lintCIMutation from '../graphql/mutations/lint_ci.mutation.graphql';

export default {
  components: {
    GlButton,
    GlFormCheckbox,
    GlIcon,
    GlLink,
    GlAlert,
    CiLintResults,
  },
  props: {
    endpoint: {
      type: String,
      required: true,
    },
    helpPagePath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      content: '',
      valid: false,
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
      try {
        const {
          data: {
            lintCI: { valid, errors, warnings, jobs },
          },
        } = await this.$apollo.mutate({
          mutation: lintCIMutation,
          variables: { endpoint: this.endpoint, content: this.content, dry: this.dryRun },
        });

        this.showingResults = true;
        this.valid = valid;
        this.errors = errors;
        this.warnings = warnings;
        this.jobs = jobs;
      } catch (error) {
        this.apiError = error;
        this.isErrorDismissed = false;
      }
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

      <textarea v-model="content" cols="175" rows="20"></textarea>
    </div>

    <div class="col-sm-12 gl-display-flex gl-justify-content-space-between">
      <div class="gl-display-flex gl-align-items-center">
        <gl-button class="gl-mr-4" category="primary" variant="success" @click="lint">{{
          __('Validate')
        }}</gl-button>
        <gl-form-checkbox v-model="dryRun"
          >{{ __('Simulate a pipeline created for the default branch') }}
          <gl-link :href="helpPagePath" target="_blank"
            ><gl-icon class="gl-text-blue-600" name="question-o"/></gl-link
        ></gl-form-checkbox>
      </div>
      <gl-button>{{ __('Clear') }}</gl-button>
    </div>

    <ci-lint-results
      v-if="showingResults"
      :valid="valid"
      :jobs="jobs"
      :errors="errors"
      :warnings="warnings"
      :dry-run="dryRun"
    />
  </div>
</template>
