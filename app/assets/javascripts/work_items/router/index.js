import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import VueRouter from 'vue-router';
import { WORKSPACE_GROUP, WORKSPACE_PROJECT } from '~/issues/constants';
import { joinPaths, webIDEUrl } from '~/lib/utils/url_utility';
import { routes } from './routes';

Vue.use(GlToast);
Vue.use(VueRouter);

export function createRouter({
  fullPath,
  workspaceType = WORKSPACE_PROJECT,
  defaultBranch,
  isGroup,
}) {
  const workspacePath = workspaceType === WORKSPACE_GROUP ? '/groups' : '';

  if (workspaceType === WORKSPACE_PROJECT) {
    window.gl.webIDEPath = webIDEUrl(joinPaths('/', fullPath, 'edit/', defaultBranch, '/-/'));
  }

  return new VueRouter({
    routes: routes(isGroup),
    mode: 'history',
    base: joinPaths(gon?.relative_url_root, workspacePath, fullPath, '-'),
  });
}
