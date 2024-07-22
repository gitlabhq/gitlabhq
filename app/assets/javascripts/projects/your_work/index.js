import Vue from 'vue';
import VueRouter from 'vue-router';
import routes from './routes';
import YourWorkProjectsApp from './components/app.vue';

Vue.use(VueRouter);

export const createRouter = () => {
  const router = new VueRouter({
    routes,
    mode: 'history',
    base: gon.relative_url_root || '/',
  });

  return router;
};

export const initYourWorkProjects = () => {
  const el = document.getElementById('js-your-work-projects-app');

  if (!el) return false;

  return new Vue({
    el,
    router: createRouter(),
    name: 'YourWorkProjectsRoot',
    render(createElement) {
      return createElement(YourWorkProjectsApp);
    },
  });
};
