import Vue from 'vue';
import VueRouter from 'vue-router';
import { joinPaths } from '~/lib/utils/url_utility';
import { routes } from './routes';

Vue.use(VueRouter);

export function createRouter(fullPath) {
  return new VueRouter({
    routes,
    mode: 'history',
    base: joinPaths(fullPath, '-', 'work_items'),
  });
}
