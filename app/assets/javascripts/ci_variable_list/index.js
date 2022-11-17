import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import CiAdminVariables from './components/ci_admin_variables.vue';
import CiGroupVariables from './components/ci_group_variables.vue';
import CiProjectVariables from './components/ci_project_variables.vue';
import { cacheConfig, resolvers } from './graphql/settings';

const mountCiVariableListApp = (containerEl) => {
  const {
    awsLogoSvgPath,
    awsTipCommandsLink,
    awsTipDeployLink,
    awsTipLearnLink,
    containsVariableReferenceLink,
    endpoint,
    environmentScopeLink,
    groupId,
    groupPath,
    isGroup,
    isProject,
    maskedEnvironmentVariablesLink,
    maskableRegex,
    projectFullPath,
    projectId,
    protectedByDefault,
    protectedEnvironmentVariablesLink,
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

  Vue.use(VueApollo);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(resolvers, cacheConfig),
  });

  return new Vue({
    el: containerEl,
    apolloProvider,
    provide: {
      awsLogoSvgPath,
      awsTipCommandsLink,
      awsTipDeployLink,
      awsTipLearnLink,
      containsVariableReferenceLink,
      endpoint,
      environmentScopeLink,
      groupId,
      groupPath,
      isGroup: parsedIsGroup,
      isProject: parsedIsProject,
      isProtectedByDefault,
      maskedEnvironmentVariablesLink,
      maskableRegex,
      projectFullPath,
      projectId,
      protectedEnvironmentVariablesLink,
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
