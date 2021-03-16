import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import CiVariableSettings from './components/ci_variable_settings.vue';
import createStore from './store';

const mountCiVariableListApp = (containerEl) => {
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

export default () => {
  const el = document.querySelector('#js-ci-project-variables');
  return !el ? {} : mountCiVariableListApp(el);
};
