import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import CiAdminVariables from './components/ci_admin_variables.vue';
import CiGroupVariables from './components/ci_group_variables.vue';
import LegacyCiVariableSettings from './components/legacy_ci_variable_settings.vue';
import { resolvers } from './graphql/resolvers';
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
  }

  Vue.use(VueApollo);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(resolvers),
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
    group,
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
  const isGroup = parseBoolean(group);
  const isProtectedByDefault = parseBoolean(protectedByDefault);

  const store = createStore({
    endpoint,
    projectId,
    isGroup,
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
