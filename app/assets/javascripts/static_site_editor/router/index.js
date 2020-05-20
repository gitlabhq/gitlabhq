import Vue from 'vue';
import VueRouter from 'vue-router';
import routes from './routes';

Vue.use(VueRouter);

export default function createRouter(base) {
  const router = new VueRouter({
    base,
    mode: 'history',
    routes,
  });

  return router;
}
