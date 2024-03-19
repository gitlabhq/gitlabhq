import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import VueRouter from 'vue-router';
import { WORKSPACE_GROUP, WORKSPACE_PROJECT } from '~/issues/constants';
import { joinPaths } from '~/lib/utils/url_utility';
import { routes } from './routes';

Vue.use(GlToast);
Vue.use(VueRouter);

export function createRouter({
  fullPath,
  workItemType = 'work_items',
  workspaceType = WORKSPACE_PROJECT,
}) {
  const workspacePath = workspaceType === WORKSPACE_GROUP ? '/groups' : '';

  return new VueRouter({
    routes: routes(),
    mode: 'history',
    base: joinPaths(gon?.relative_url_root, workspacePath, fullPath, '-', workItemType),
  });
}
