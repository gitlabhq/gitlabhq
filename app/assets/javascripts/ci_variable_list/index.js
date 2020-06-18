import Vue from 'vue';
import CiVariableSettings from './components/ci_variable_settings.vue';
import createStore from './store';
import { parseBoolean } from '~/lib/utils/common_utils';

export default (containerId = 'js-ci-project-variables') => {
  const containerEl = document.getElementById(containerId);
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
    protectedEnvironmentVariablesLink,
    maskedEnvironmentVariablesLink,
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
    protectedEnvironmentVariablesLink,
    maskedEnvironmentVariablesLink,
  });

  return new Vue({
    el: containerEl,
    store,
    render(createElement) {
      return createElement(CiVariableSettings);
    },
  });
};
