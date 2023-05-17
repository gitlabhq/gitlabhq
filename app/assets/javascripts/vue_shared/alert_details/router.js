import Vue from 'vue';
import VueRouter from 'vue-router';
import { joinPaths } from '~/lib/utils/url_utility';

Vue.use(VueRouter);

export default function createRouter(base) {
  return new VueRouter({
    mode: 'history',
    base: joinPaths(gon.relative_url_root || '', base),
    routes: [{ path: '/:tabId', name: 'tab' }],
  });
}
