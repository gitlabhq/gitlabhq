import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import CiAdminVariables from './components/ci_admin_variables.vue';
import CiGroupVariables from './components/ci_group_variables.vue';
import CiProjectVariables from './components/ci_project_variables.vue';
import LegacyCiVariableSettings from './components/legacy_ci_variable_settings.vue';
import { cacheConfig, resolvers } from './graphql/settings';
import createStore from './store';

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

const mountLegacyCiVariableListApp = (containerEl) => {
  const {
    endpoint,
    projectId,
    isGroup,
    maskableRegex,
    protectedByDefault,
    awsLogoSvgPath,
    awsTipDeployLink,
    awsTipCommandsLink,
    awsTipLearnLink,
    containsVariableReferenceLink,
    protectedEnvironmentVariablesLink,
    maskedEnvironmentVariablesLink,
    environmentScopeLink,
  } = containerEl.dataset;
  const parsedIsGroup = parseBoolean(isGroup);
  const isProtectedByDefault = parseBoolean(protectedByDefault);

  const store = createStore({
    endpoint,
    projectId,
    isGroup: parsedIsGroup,
    maskableRegex,
    isProtectedByDefault,
    awsLogoSvgPath,
    awsTipDeployLink,
    awsTipCommandsLink,
    awsTipLearnLink,
    containsVariableReferenceLink,
    protectedEnvironmentVariablesLink,
    maskedEnvironmentVariablesLink,
    environmentScopeLink,
  });

  return new Vue({
    el: containerEl,
    store,
    render(createElement) {
      return createElement(LegacyCiVariableSettings);
    },
  });
};

export default (containerId = 'js-ci-project-variables') => {
  const el = document.getElementById(containerId);

  if (el) {
    if (gon.features?.ciVariableSettingsGraphql) {
      mountCiVariableListApp(el);
    } else {
      mountLegacyCiVariableListApp(el);
    }
  }
};
