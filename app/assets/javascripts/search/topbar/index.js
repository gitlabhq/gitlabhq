import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import GlobalSearchTopbar from './components/app.vue';

Vue.use(Translate);

export const initTopbar = (store) => {
  const el = document.getElementById('js-search-topbar');

  if (!el) {
    return false;
  }

  const {
    groupInitialJson,
    projectInitialJson,
    elasticsearchEnabled,
    defaultBranchName,
  } = el.dataset;

  const groupInitialJsonParsed = JSON.parse(groupInitialJson);
  const projectInitialJsonParsed = JSON.parse(projectInitialJson);
  const elasticsearchEnabledParsed = elasticsearchEnabled
    ? JSON.parse(elasticsearchEnabled)
    : false;

  return new Vue({
    el,
    store,
    render(createElement) {
      return createElement(GlobalSearchTopbar, {
        props: {
          groupInitialJson: groupInitialJsonParsed,
          projectInitialJson: projectInitialJsonParsed,
          elasticsearchEnabled: elasticsearchEnabledParsed,
          defaultBranchName,
        },
      });
    },
  });
};
