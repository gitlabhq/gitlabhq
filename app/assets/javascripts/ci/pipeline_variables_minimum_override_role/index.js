import Vue from 'vue';
import VueApollo from 'vue-apollo';
import PipelinesMinimumOverrideRole from '~/ci/pipeline_variables_minimum_override_role/pipeline_variables_minimum_override_role.vue';
import createDefaultClient from '~/lib/graphql';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default (containerId = 'js-ci-variables-minimum-override-role-app') => {
  const containerEl = document.getElementById(containerId);

  if (!containerEl) {
    return false;
  }

  const { fullPath } = containerEl.dataset;

  return new Vue({
    el: containerEl,
    name: 'PipelineVariablesMinimumOverrideRoleRoot',
    apolloProvider,
    provide: {
      fullPath,
    },
    render(createElement) {
      return createElement(PipelinesMinimumOverrideRole);
    },
  });
};
