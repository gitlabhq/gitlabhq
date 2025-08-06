import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import PipelineVariablesDefaultRole from './pipeline_variables_default_role.vue';
import PipelineVariablesMigration from './pipeline_variables_migration.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default (containerId = 'js-pipeline-variables-default-role') => {
  const containerEl = document.getElementById(containerId);

  if (!containerEl) {
    return false;
  }

  const { fullPath } = containerEl.dataset;

  return new Vue({
    el: containerEl,
    name: 'PipelineVariablesRootGroupSettings',
    apolloProvider,
    components: {
      PipelineVariablesDefaultRole,
      PipelineVariablesMigration,
    },
    provide: {
      fullPath,
    },
    render(createElement) {
      return createElement('div', [
        createElement(PipelineVariablesDefaultRole),
        createElement(PipelineVariablesMigration),
      ]);
    },
  });
};
