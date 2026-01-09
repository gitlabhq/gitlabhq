import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import VueRouter from 'vue-router';
import { WORKSPACE_GROUP, WORKSPACE_PROJECT } from '~/issues/constants';
import { joinPaths, webIDEUrl } from '~/lib/utils/url_utility';
import { WORK_ITEM_TYPE_NAME_TICKET } from '../constants';
import { routes } from './routes';

Vue.use(GlToast);
Vue.use(VueRouter);

export function createRouter({
  fullPath,
  workspaceType = WORKSPACE_PROJECT,
  defaultBranch,
  workItemType,
}) {
  const workspacePath = workspaceType === WORKSPACE_GROUP ? '/groups' : '';
  const base =
    workItemType === WORK_ITEM_TYPE_NAME_TICKET
      ? joinPaths(gon?.relative_url_root, workspacePath, fullPath, '-', 'issues')
      : joinPaths(gon?.relative_url_root, workspacePath, fullPath, '-');

  if (workspaceType === WORKSPACE_PROJECT) {
    window.gl.webIDEPath = webIDEUrl(joinPaths('/', fullPath, 'edit/', defaultBranch, '/-/'));
  }

  return new VueRouter({
    routes: routes(fullPath),
    mode: 'history',
    base,
  });
}
