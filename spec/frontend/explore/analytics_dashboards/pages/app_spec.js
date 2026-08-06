import { nextTick } from 'vue';
import { observable, resetObservable } from '~/lib/utils/observable';
import { ignoreConsoleMessages } from 'helpers/console_watcher';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createRouter from '~/explore/analytics_dashboards/router';
import App from '~/explore/analytics_dashboards/pages/app.vue';

const BREADCRUMB_STATE_KEY = 'explore_analytics_dashboards_breadcrumb';

describe('ExploreAnalyticsDashboards', () => {
  const basePath = '/explore/analytics_dashboards';

  let breadcrumbState;
  let router;

  beforeEach(() => {
    breadcrumbState = observable(BREADCRUMB_STATE_KEY, { name: '', slug: '' });
    router = createRouter(basePath, breadcrumbState);
  });

  // observable() ignores its defaults once the key exists, so the name would
  // otherwise persist into the next test.
  afterEach(() => {
    resetObservable(BREADCRUMB_STATE_KEY);
  });

  const createWrapper = () => {
    shallowMountExtended(App, {
      router,
      propsData: { currentUserId: 'gid://gitlab/User/1' },
    });
  };

  describe('document title', () => {
    const baseTitle = 'Analytics dashboards · GitLab';

    // Captured in data() on mount, so it has to be in place before createWrapper.
    beforeEach(() => {
      document.title = baseTitle;
    });

    afterEach(() => {
      document.title = '';
    });

    it('keeps the server-rendered title on the root route', () => {
      createWrapper();

      expect(document.title).toBe(baseTitle);
    });

    it('keeps the base title while the dashboard is still loading', async () => {
      await router.push('/3');

      createWrapper();

      expect(document.title).toBe(baseTitle);
    });

    it('prepends the dashboard name on the detail route', async () => {
      breadcrumbState.name = 'My dashboard';
      await router.push('/3');

      createWrapper();

      expect(document.title).toBe(`My dashboard · ${baseTitle}`);
    });

    it('updates the title when the dashboard name arrives after the route change', async () => {
      await router.push('/3');
      createWrapper();

      breadcrumbState.name = 'My dashboard';
      await nextTick();

      expect(document.title).toBe(`My dashboard · ${baseTitle}`);
    });

    it('resets the title when navigating back to the list', async () => {
      breadcrumbState.name = 'My dashboard';
      await router.push('/3');
      createWrapper();

      await router.push('/');

      expect(document.title).toBe(baseTitle);
    });

    // The Rails route is a wildcard, so unmatched subpaths still mount the app.
    describe('when no route matches', () => {
      // Vue Router 4 warns on unmatched navigation; Vue Router 3 does not.
      ignoreConsoleMessages([/No match found for location/]);

      it('keeps the base title', async () => {
        await router.push('/3/unknown');

        createWrapper();

        expect(document.title).toBe(baseTitle);
      });
    });
  });
});
