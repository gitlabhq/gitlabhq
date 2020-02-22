import Vue from 'vue';
import CiVariableSettings from './components/ci_variable_settings.vue';
import createStore from './store';
import { parseBoolean } from '~/lib/utils/common_utils';

export default () => {
  const el = document.getElementById('js-ci-project-variables');
  const { endpoint, projectId, group, maskableRegex } = el.dataset;
  const isGroup = parseBoolean(group);

  const store = createStore({
    endpoint,
    projectId,
    isGroup,
    maskableRegex,
  });

  return new Vue({
    el,
    store,
    render(createElement) {
      return createElement(CiVariableSettings);
    },
  });
};
