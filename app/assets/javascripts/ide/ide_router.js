import Vue from 'vue';
import VueRouter from 'vue-router';
import { joinPaths } from '~/lib/utils/url_utility';
import flash from '~/flash';
import store from './stores';
import { __ } from '~/locale';

Vue.use(VueRouter);

/**
 * Routes below /-/ide/:

/project/h5bp/html5-boilerplate/blob/master
/project/h5bp/html5-boilerplate/blob/master/app/js/test.js

/project/h5bp/html5-boilerplate/mr/123
/project/h5bp/html5-boilerplate/mr/123/app/js/test.js

/workspace/123
/workspace/project/h5bp/html5-boilerplate/blob/my-special-branch
/workspace/project/h5bp/html5-boilerplate/mr/123

/ = /workspace

/settings
*/

// Unfortunately Vue Router doesn't work without at least a fake component
// If you do only data handling
const EmptyRouterComponent = {
  render(createElement) {
    return createElement('div');
  },
};

const router = new VueRouter({
  mode: 'history',
  base: joinPaths(gon.relative_url_root || '', '/-/ide/'),
  routes: [
    {
      path: '/project/:namespace+/:project',
      component: EmptyRouterComponent,
      children: [
        {
          path: ':targetmode(edit|tree|blob)/:branchid+/-/*',
          component: EmptyRouterComponent,
        },
        {
          path: ':targetmode(edit|tree|blob)/:branchid+/',
          redirect: to => joinPaths(to.path, '/-/'),
        },
        {
          path: ':targetmode(edit|tree|blob)',
          redirect: to => joinPaths(to.path, '/master/-/'),
        },
        {
          path: 'merge_requests/:mrid',
          component: EmptyRouterComponent,
        },
        {
          path: '',
          redirect: to => joinPaths(to.path, '/edit/master/-/'),
        },
      ],
    },
  ],
});

router.beforeEach((to, from, next) => {
  if (to.params.namespace && to.params.project) {
    store
      .dispatch('getProjectData', {
        namespace: to.params.namespace,
        projectId: to.params.project,
      })
      .then(() => {
        const basePath = to.params.pathMatch || '';
        const projectId = `${to.params.namespace}/${to.params.project}`;
        const branchId = to.params.branchid;
        const mergeRequestId = to.params.mrid;

        if (branchId) {
          store.dispatch('openBranch', {
            projectId,
            branchId,
            basePath,
          });
        } else if (mergeRequestId) {
          store.dispatch('openMergeRequest', {
            projectId,
            mergeRequestId,
            targetProjectId: to.query.target_project,
          });
        }
      })
      .catch(e => {
        flash(
          __('Error while loading the project data. Please try again.'),
          'alert',
          document,
          null,
          false,
          true,
        );
        throw e;
      });
  }

  next();
});

export default router;
