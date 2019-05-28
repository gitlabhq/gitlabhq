import Vue from 'vue';
import createRouter from './router';
import App from './components/app.vue';
import apolloProvider from './graphql';
import { setTitle } from './utils/title';

export default function setupVueRepositoryList() {
  const el = document.getElementById('js-tree-list');
  const { projectPath, ref, fullName } = el.dataset;
  const router = createRouter(projectPath, ref);

  apolloProvider.clients.defaultClient.cache.writeData({
    data: {
      projectPath,
      ref,
    },
  });

  router.afterEach(({ params: { pathMatch } }) => setTitle(pathMatch, ref, fullName));
  router.afterEach(to => {
    const isRoot = to.params.pathMatch === undefined || to.params.pathMatch === '/';

    if (!isRoot) {
      document
        .querySelectorAll('.js-keep-hidden-on-navigation')
        .forEach(elem => elem.classList.add('hidden'));
    }

    document
      .querySelectorAll('.js-hide-on-navigation')
      .forEach(elem => elem.classList.toggle('hidden', !isRoot));
  });

  return new Vue({
    el,
    router,
    apolloProvider,
    render(h) {
      return h(App);
    },
  });
}
