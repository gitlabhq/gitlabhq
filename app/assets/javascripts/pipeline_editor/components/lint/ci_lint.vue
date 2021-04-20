<script>
import { flatten } from 'lodash';
import CiLintResults from './ci_lint_results.vue';

export default {
  components: {
    CiLintResults,
  },
  inject: {
    lintHelpPagePath: {
      default: '',
    },
  },
  props: {
    isValid: {
      type: Boolean,
      required: true,
    },
    ciConfig: {
      type: Object,
      required: true,
    },
  },
  computed: {
    stages() {
      return this.ciConfig?.stages || [];
    },
    jobs() {
      const groupedJobs = this.stages.reduce((acc, { groups, name: stageName }) => {
        return acc.concat(
          groups.map(({ jobs }) => {
            return jobs.map((job) => ({
              stage: stageName,
              ...job,
            }));
          }),
        );
      }, []);

      return flatten(groupedJobs);
    },
  },
};
</script>

<template>
  <ci-lint-results
    :errors="ciConfig.errors"
    :is-valid="isValid"
    :jobs="jobs"
    :lint-help-page-path="lintHelpPagePath"
  />
</template>
