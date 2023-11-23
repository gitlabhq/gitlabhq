import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { removeLastSlashInUrlPath } from '~/lib/utils/url_utility';
import csrf from '~/lib/utils/csrf';
import { apolloProvider as createApolloProvider } from './graphql/client';
import App from './pages/app.vue';
import createRouter from './router/index';

Vue.use(VueApollo);

const initKubernetesDashboard = () => {
  const el = document.querySelector('.js-kubernetes-app');

  if (!el) {
    return null;
  }

  const { basePath, agent, kasTunnelUrl } = el.dataset;
  const agentObject = JSON.parse(agent);

  const configuration = {
    basePath: removeLastSlashInUrlPath(kasTunnelUrl),
    headers: {
      'GitLab-Agent-Id': agentObject.id,
      'Content-Type': 'application/json',
      ...csrf.headers,
    },
    credentials: 'include',
  };

  const router = createRouter({
    base: basePath,
  });

  return new Vue({
    el,
    name: 'KubernetesDashboardRoot',
    router,
    apolloProvider: createApolloProvider(),
    provide: {
      agent: agentObject,
      configuration,
    },
    render: (createElement) => createElement(App),
  });
};

export { initKubernetesDashboard };
