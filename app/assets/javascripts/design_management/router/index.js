import $ from 'jquery';
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

  router.beforeEach(({ meta: { el } }, from, next) => {
    $(`#${el}`).tab('show');

    next();
  });

  return router;
}
