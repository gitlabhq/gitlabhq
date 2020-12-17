import Vue from 'vue';
import IdeRouter from '~/ide/ide_router_extension';
import { joinPaths } from '~/lib/utils/url_utility';
import { deprecatedCreateFlash as flash } from '~/flash';
import { __ } from '~/locale';
import { performanceMarkAndMeasure } from '~/performance/utils';
import {
  WEBIDE_MARK_FETCH_PROJECT_DATA_START,
  WEBIDE_MARK_FETCH_PROJECT_DATA_FINISH,
  WEBIDE_MEASURE_FETCH_PROJECT_DATA,
} from '~/performance/constants';
import { syncRouterAndStore } from './sync_router_and_store';

Vue.use(IdeRouter);

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

export const createRouter = store => {
  const router = new IdeRouter({
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
      performanceMarkAndMeasure({ mark: WEBIDE_MARK_FETCH_PROJECT_DATA_START });
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
            performanceMarkAndMeasure({
              mark: WEBIDE_MARK_FETCH_PROJECT_DATA_FINISH,
              measures: [
                {
                  name: WEBIDE_MEASURE_FETCH_PROJECT_DATA,
                  start: WEBIDE_MARK_FETCH_PROJECT_DATA_START,
                },
              ],
            });
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

  syncRouterAndStore(router, store);

  return router;
};
