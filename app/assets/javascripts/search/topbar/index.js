import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import GlobalSearchTopbar from './components/app.vue';

Vue.use(Translate);

export const initTopbar = (store) => {
  const el = document.getElementById('js-search-topbar');

  if (!el) {
    return false;
  }

  const { groupInitialJson, projectInitialJson, defaultBranchName } = el.dataset;

  const groupInitialJsonParsed = JSON.parse(groupInitialJson);
  const projectInitialJsonParsed = JSON.parse(projectInitialJson);

  return new Vue({
    el,
    store,
    render(createElement) {
      return createElement(GlobalSearchTopbar, {
        props: {
          groupInitialJson: groupInitialJsonParsed,
          projectInitialJson: projectInitialJsonParsed,
          defaultBranchName,
        },
      });
    },
  });
};
