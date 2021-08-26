import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import StorageCounterApp from './components/app.vue';

Vue.use(VueApollo);

export default (containerId = 'js-project-storage-count-app') => {
  const el = document.getElementById(containerId);

  if (!el) {
    return false;
  }

  const { projectPath } = el.dataset;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient({}, { assumeImmutableResults: true }),
  });

  return new Vue({
    el,
    apolloProvider,
    provide: {
      projectPath,
    },
    render(createElement) {
      return createElement(StorageCounterApp);
    },
  });
};
