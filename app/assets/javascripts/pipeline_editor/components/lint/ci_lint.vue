<script>
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
      return this.stages.reduce((acc, { groups, name: stageName }) => {
        return acc.concat(
          groups.map(({ name: groupName }) => ({
            stage: stageName,
            name: groupName,
          })),
        );
      }, []);
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
