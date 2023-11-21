import Vue from 'vue';
import App from './pages/app.vue';
import createRouter from './router/index';

const initKubernetesDashboard = () => {
  const el = document.querySelector('.js-kubernetes-app');

  if (!el) {
    return null;
  }

  const { basePath, agent } = el.dataset;

  const router = createRouter({
    base: basePath,
  });

  return new Vue({
    el,
    name: 'KubernetesDashboardRoot',
    router,
    provide: {
      agent: JSON.parse(agent),
    },
    render: (createElement) => createElement(App),
  });
};

export { initKubernetesDashboard };
