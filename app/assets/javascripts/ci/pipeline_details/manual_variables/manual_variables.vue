<script>
import { GlLoadingIcon } from '@gitlab/ui';
import EmptyState from './empty_state.vue';
import VariableTable from './variable_table.vue';
import getManualVariablesQuery from './graphql/queries/get_manual_variables.query.graphql';

export default {
  name: 'ManualVariablesApp',
  components: {
    EmptyState,
    GlLoadingIcon,
    VariableTable,
  },
  inject: ['manualVariablesCount', 'projectPath', 'pipelineIid', 'displayPipelineVariables'],
  apollo: {
    variables: {
      query: getManualVariablesQuery,
      skip() {
        return !this.hasManualVariables;
      },
      update({ project }) {
        return project?.pipeline?.manualVariables?.nodes || [];
      },
      variables() {
        return {
          projectPath: this.projectPath,
          iid: this.pipelineIid,
        };
      },
    },
  },
  data() {
    return {
      variables: [],
    };
  },
  computed: {
    loading() {
      return this.$apollo.queries.variables.loading;
    },
    hasManualVariables() {
      return Boolean(this.manualVariablesCount > 0);
    },
    shouldShowManualVariables() {
      return this.hasManualVariables && this.displayPipelineVariables;
    },
  },
};
</script>

<template>
  <div>
    <div v-if="shouldShowManualVariables" class="manual-variables-table">
      <gl-loading-icon v-if="loading" />
      <variable-table v-else :variables="variables" />
    </div>
    <empty-state v-else />
  </div>
</template>
