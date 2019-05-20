import Vue from 'vue';
import createRouter from './router';
import App from './components/app.vue';
import apolloProvider from './graphql';

export default function setupVueRepositoryList() {
  const el = document.getElementById('js-tree-list');
  const { projectPath, ref } = el.dataset;

  apolloProvider.clients.defaultClient.cache.writeData({
    data: {
      projectPath,
      ref,
    },
  });

  return new Vue({
    el,
    router: createRouter(projectPath, ref),
    apolloProvider,
    render(h) {
      return h(App);
    },
  });
}
