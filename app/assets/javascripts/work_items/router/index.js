import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import VueRouter from 'vue-router';
import { NAMESPACE_GROUP, NAMESPACE_PROJECT } from '~/issues/constants';
import { joinPaths, webIDEUrl } from '~/lib/utils/url_utility';
import { WORK_ITEM_TYPE_NAME_TICKET } from '../constants';
import { routes } from './routes';

Vue.use(GlToast);
Vue.use(VueRouter);

export function createRouter({
  fullPath,
  namespaceType = NAMESPACE_PROJECT,
  defaultBranch,
  workItemType,
}) {
  const namespacePath = namespaceType === NAMESPACE_GROUP ? '/groups' : '';
  const base =
    workItemType === WORK_ITEM_TYPE_NAME_TICKET
      ? joinPaths(gon?.relative_url_root, namespacePath, fullPath, '-', 'issues')
      : joinPaths(gon?.relative_url_root, namespacePath, fullPath, '-');

  if (namespaceType === NAMESPACE_PROJECT) {
    window.gl.webIDEPath = webIDEUrl(joinPaths('/', fullPath, 'edit/', defaultBranch, '/-/'));
  }

  return new VueRouter({
    routes: routes(fullPath),
    mode: 'history',
    base,
  });
}
