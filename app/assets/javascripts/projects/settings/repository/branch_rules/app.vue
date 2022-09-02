<script>
import { __ } from '~/locale';
import createFlash from '~/flash';
import branchRulesQuery from './graphql/queries/branch_rules.query.graphql';

export const i18n = {
  heading: __('Branch'),
  queryError: __('An error occurred while loading branch rules. Please try again.'),
};

export default {
  name: 'BranchRules',
  i18n,
  apollo: {
    branchRules: {
      query: branchRulesQuery,
      variables() {
        return {
          projectPath: this.projectPath,
        };
      },
      update(data) {
        return data.project?.branchRules?.nodes || [];
      },
      error() {
        createFlash({ message: this.$options.i18n.queryError });
      },
    },
  },
  props: {
    projectPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      branchRules: [],
    };
  },
};
</script>

<template>
  <div>
    <strong>{{ $options.i18n.heading }}</strong>

    <!-- TODO - List branch rules (https://gitlab.com/gitlab-org/gitlab/-/issues/362217) -->
  </div>
</template>
