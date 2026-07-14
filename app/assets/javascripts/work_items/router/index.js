import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import VueRouter from 'vue-router';
import { joinPaths, webIDEUrl } from '~/lib/utils/url_utility';
import { routes } from './routes';

Vue.use(GlToast);
Vue.use(VueRouter);

export function createRouter({ fullPath, defaultBranch, routerPath }) {
  if (defaultBranch) {
    // eslint-disable-next-line @gitlab/no-hardcoded-urls -- not ideal but acceptable in this case as there is no JavaScript path helper available
    window.gl.webIDEPath = webIDEUrl(joinPaths('/', fullPath, 'edit/', defaultBranch, '/-/'));
  }

  return new VueRouter({
    routes: routes(fullPath),
    mode: 'history',
    base: routerPath.replace(/\/work_items$/, ''),
  });
}
