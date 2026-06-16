import { shallowMount } from '@vue/test-utils';
import VueRouter from 'vue-router';
import Vue, { defineComponent } from 'vue';
import { GlBreadcrumb } from '@gitlab/ui';
import AnalyticsDashboardsBreadcrumbs from '~/analytics/shared/components/analytics_dashboards_breadcrumbs.vue';

Vue.use(VueRouter);

describe('AnalyticsDashboardsBreadcrumbs', () => {
  const MockComponent = defineComponent({
    name: 'MockComponent',
    template: '<div>Mock</div>',
  });

  const breadcrumbState = {
    name: '',
    slug: '',
  };

  const rootBreadcrumb = {
    text: 'Analytics dashboards',
    to: '/',
  };

  const mockRouter = {
    mode: 'history',
    base: '/dashboard',
    routes: [
      {
        name: 'root',
        path: rootBreadcrumb.to,
        component: MockComponent,
        meta: {
          getName: () => rootBreadcrumb.text,
          root: true,
        },
      },
      {
        name: 'dashboard-detail',
        path: '/:slug',
        component: MockComponent,
        meta: {
          getName: () => breadcrumbState.name,
        },
      },
      {
        name: 'dashboard-edit',
        path: '/:slug/edit',
        component: MockComponent,
        meta: {
          getName: () => 'Edit',
          getParents: () => [{ text: breadcrumbState.name, to: `/${breadcrumbState.slug}` }],
        },
      },
    ],
  };

  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;
  let router;

  const mockRoute = {
    meta: {
      getName: jest.fn(),
      getParents: jest.fn(() => []),
    },
  };

  const createWrapper = ({ props = {}, mocks = {} } = {}) => {
    router = new VueRouter(mockRouter);

    wrapper = shallowMount(AnalyticsDashboardsBreadcrumbs, {
      router,
      propsData: { staticBreadcrumbs: [], ...props },
      global: {
        mocks: {
          $route: mockRoute,
          ...mocks,
        },
      },
    });
  };

  const findBreadcrumbs = () => wrapper.findComponent(GlBreadcrumb);

  describe('when mounted', () => {
    afterEach(() => {
      breadcrumbState.name = '';
      breadcrumbState.slug = '';
    });

    beforeEach(() => {
      createWrapper();
    });

    it('should render only the root breadcrumb when on the root route', async () => {
      try {
        await router.push('/');
      } catch {
        // intentionally blank
        //
        // * in Vue.js 3 we need to refresh even '/' route
        // because we dynamically add routes and exception will not be raised
        //
        // * in Vue.js 2 this will trigger "redundant navigation" error and will be caught here
      }

      expect(findBreadcrumbs().props('items')).toStrictEqual([rootBreadcrumb]);
    });

    it('should render only the root breadcrumb when the dashboard is unknown', async () => {
      try {
        await router.push('/');
      } catch {
        // intentionally blank
        //
        // * in Vue.js 3 we need to refresh even '/' route
        // because we dynamically add routes and exception will not be raised
        //
        // * in Vue.js 2 this will trigger "redundant navigation" error and will be caught here
      }

      expect(findBreadcrumbs().props('items')).toStrictEqual([rootBreadcrumb]);
    });

    it('should render the root and dashboard breadcrumbs when on a dashboard', async () => {
      createWrapper({
        mocks: {
          $route: {
            meta: {
              getName: jest.fn().mockReturnValue('Test dashboard 1'),
            },
            name: 'dashboards',
          },
        },
      });
      breadcrumbState.name = 'Test dashboard 1';

      await router.push('/test-dashboard-1');

      expect(findBreadcrumbs().props('items')).toStrictEqual([
        rootBreadcrumb,
        {
          text: 'Test dashboard 1',
          to: undefined,
        },
      ]);
    });

    it('should render the current breadcrumb with any intermediary breadcrumbs', async () => {
      const parents = [{ text: 'Test dashboard', to: '/123' }];

      createWrapper({
        mocks: {
          $route: {
            meta: {
              getName: () => 'Edit',
              getParents: () => parents,
            },
            name: 'dashboard-edit',
          },
        },
      });
      breadcrumbState.name = 'Test dashboard';
      breadcrumbState.slug = '123';

      await router.push('/test-dashboard-1/edit');

      expect(findBreadcrumbs().props('items')).toStrictEqual([
        rootBreadcrumb,
        ...parents,
        {
          text: 'Edit',
          to: undefined,
        },
      ]);
    });

    it('should disable auto-resize behavior', () => {
      expect(findBreadcrumbs().props('autoResize')).toEqual(false);
    });
  });
});
