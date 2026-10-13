import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { parseBoolean } from '@gitlab/frontend-utils';
import PerformancePlugin from '~/performance/vue_performance_plugin';
import createStore from '~/code_navigation/store';
import HighlightWorker from '~/highlight_js/workers/highlight_worker?worker';
import initFileTreeBrowser from '~/repository/file_tree_browser';
import initHeaderApp from './init_header_app';
import initLastCommitApp from './init_last_commit_app';
import initForkInfoApp from './init_fork_info_app';
import RepositoryApp from './components/app.vue';

import apolloProvider from './graphql';
import projectPathQuery from './queries/project_path.query.graphql';
import projectShortPathQuery from './queries/project_short_path.query.graphql';
import refsQuery from './queries/ref.query.graphql';
import createRouter from './router';

Vue.use(Vuex);
Vue.use(PerformancePlugin, {
  components: ['SimpleViewer', 'BlobContent'],
});

export default function setupVueRepositoryList() {
  const el = document.getElementById('js-tree-list');
  if (!el) return null;

  const { dataset } = el;
  const {
    projectPath,
    projectShortPath,
    ref,
    escapedRef,
    fullName,
    resourceId,
    explainCodeAvailable,
    refType,
    hasRevsFile,
  } = dataset;
  const router = createRouter(projectPath, escapedRef, fullName);

  initFileTreeBrowser(router, { projectPath, ref, refType });

  apolloProvider.clients.defaultClient.cache.writeQuery({
    query: projectPathQuery,
    data: {
      projectPath,
    },
  });

  apolloProvider.clients.defaultClient.cache.writeQuery({
    query: projectShortPathQuery,
    data: {
      projectShortPath,
    },
  });

  apolloProvider.clients.defaultClient.cache.writeQuery({
    query: refsQuery,
    data: {
      ref,
      escapedRef,
    },
  });

  initHeaderApp({ router });
  initLastCommitApp(router);
  initForkInfoApp();

  // eslint-disable-next-line no-new
  new Vue({
    el,
    name: 'RepositoryAppRoot',
    store: createStore(),
    router,
    apolloProvider,
    provide: {
      resourceId,
      explainCodeAvailable: parseBoolean(explainCodeAvailable),
      highlightWorker: new HighlightWorker(),
      hasRevsFile: parseBoolean(hasRevsFile),
    },
    render(h) {
      return h(RepositoryApp);
    },
  });

  return { router, data: dataset, apolloProvider, projectPath };
}
