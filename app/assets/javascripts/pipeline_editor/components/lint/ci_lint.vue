<script>
import { flatten } from 'lodash';
import { CI_CONFIG_STATUS_VALID } from '../../constants';
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
    ciConfig: {
      type: Object,
      required: true,
    },
  },
  computed: {
    isValid() {
      return this.ciConfig?.status === CI_CONFIG_STATUS_VALID;
    },
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
    :valid="isValid"
    :jobs="jobs"
    :errors="ciConfig.errors"
    :lint-help-page-path="lintHelpPagePath"
  />
</template>
