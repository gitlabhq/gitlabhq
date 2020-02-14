import Vue from 'vue';
import ReleaseListApp from './components/app_index.vue';
import createStore from './stores';
import listModule from './stores/modules/list';

export default () => {
  const el = document.getElementById('js-releases-page');

  return new Vue({
    el,
    store: createStore({ list: listModule }),
    render: h =>
      h(ReleaseListApp, {
        props: {
          projectId: el.dataset.projectId,
          documentationLink: el.dataset.documentationPath,
          illustrationPath: el.dataset.illustrationPath,
        },
      }),
  });
};
