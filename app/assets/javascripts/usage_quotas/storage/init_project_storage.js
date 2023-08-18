import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import ProjectStorageApp from './components/project_storage_app.vue';

Vue.use(VueApollo);

export default (containerId = 'js-project-storage-count-app') => {
  const el = document.getElementById(containerId);

  if (!el) {
    return false;
  }

  const { projectPath } = el.dataset;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    apolloProvider,
    name: 'ProjectStorageApp',
    provide: {
      projectPath,
    },
    render(createElement) {
      return createElement(ProjectStorageApp);
    },
  });
};
