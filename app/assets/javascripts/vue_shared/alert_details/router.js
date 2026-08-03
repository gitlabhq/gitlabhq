import Vue from 'vue';
import VueRouter from 'vue-router';

Vue.use(VueRouter);

export default function createRouter(base) {
  return new VueRouter({
    mode: 'history',
    base,
    routes: [{ path: '/:tabId', name: 'tab' }],
  });
}
