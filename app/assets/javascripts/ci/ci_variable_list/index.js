import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlToast } from '@gitlab/ui';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import CiAdminVariables from './components/ci_admin_variables.vue';
import CiGroupVariables from './components/ci_group_variables.vue';
import CiProjectVariables from './components/ci_project_variables.vue';
import { generateCacheConfig, resolvers } from './graphql/settings';

const mountCiVariableListApp = (containerEl) => {
  const {
    containsVariableReferenceLink,
    endpoint,
    groupId,
    groupPath,
    isGroup,
    isProject,
    maskedEnvironmentVariablesLink,
    maskableRawRegex,
    maskableRegex,
    projectFullPath,
    projectId,
    protectedByDefault,
  } = containerEl.dataset;

  const parsedIsProject = parseBoolean(isProject);
  const parsedIsGroup = parseBoolean(isGroup);
  const isProtectedByDefault = parseBoolean(protectedByDefault);

  let component = CiAdminVariables;

  if (parsedIsGroup) {
    component = CiGroupVariables;
  } else if (parsedIsProject) {
    component = CiProjectVariables;
  }

  Vue.use(GlToast);
  Vue.use(VueApollo);

  // If the feature flag `ci_variables_pages` is enabled,
  // we are using the default cache config with pages.
  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(
      resolvers,
      generateCacheConfig(window.gon?.features?.ciVariablesPages),
    ),
  });

  return new Vue({
    el: containerEl,
    apolloProvider,
    provide: {
      containsVariableReferenceLink,
      endpoint,
      groupId,
      groupPath,
      isGroup: parsedIsGroup,
      isInheritedGroupVars: false,
      isProject: parsedIsProject,
      isProtectedByDefault,
      maskedEnvironmentVariablesLink,
      maskableRawRegex,
      maskableRegex,
      projectFullPath,
      projectId,
    },
    render(createElement) {
      return createElement(component);
    },
  });
};

export default (containerId = 'js-ci-variables') => {
  const el = document.getElementById(containerId);

  if (!el) return;

  mountCiVariableListApp(el);
};
