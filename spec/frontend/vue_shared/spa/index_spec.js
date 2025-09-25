import Vue from 'vue';
import VueRouter from 'vue-router';
import { shallowMount } from '@vue/test-utils';
import { initSinglePageApplication } from '~/vue_shared/spa';
import { injectVueAppBreadcrumbs } from '~/lib/utils/breadcrumbs';
import { activeNavigationWatcher } from '~/vue_shared/spa/utils/';
import { resetHTMLFixture, setHTMLFixture } from 'helpers/fixtures';
import RootComponent from '~/vue_shared/spa/components/spa_root.vue';

jest.mock('~/lib/utils/breadcrumbs');
jest.mock('~/vue_shared/spa/utils');
jest.mock('~/lib/graphql', () => jest.fn(() => ({})));

Vue.use(VueRouter);

const routerViewStub = {
  template: `<div><slot :Component="mockComponent" /></div>`,
  data() {
    return {
      mockComponent: 'router-view-stub', // or whatever mock component you want
    };
  },
};

describe('initSinglePageApplication', () => {
  let mockRouter;
  let mockEl;
  let wrapper;

  const findRootComponent = () => wrapper.find('#single-page-app');

  const createWrapper = (props = {}) => {
    wrapper = shallowMount(RootComponent, {
      propsData: props,
      router: mockRouter,
      stubs: {
        routerViewStub,
      },
    });
    return wrapper;
  };

  beforeEach(() => {
    setHTMLFixture('<div id="app"></div>');
    mockEl = document.getElementById('app');
    mockRouter = new VueRouter({
      routes: [{ path: '/', component: { render: (h) => h('div', 'Home') } }],
    });

    mockRouter.beforeEach = jest.fn();
    injectVueAppBreadcrumbs.mockReturnValue(true);
    activeNavigationWatcher.mockImplementation(() => {});
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('when required parameters are missing', () => {
    describe('when el is not provided', () => {
      it('throws error', () => {
        expect(() => {
          initSinglePageApplication({
            router: mockRouter,
          });
        }).toThrow('You must provide a `el` prop to initSinglePageApplication');
      });
    });

    describe('when router is not provided', () => {
      it('throws error', () => {
        expect(() => {
          initSinglePageApplication({
            el: mockEl,
          });
        }).toThrow('You must provide a `router` prop to initSinglePageApplication');
      });
    });
  });

  describe('when required parameters are provided', () => {
    describe('when creating Vue instance with default name', () => {
      it('creates Vue instance with default name', () => {
        const app = initSinglePageApplication({
          el: mockEl,
          router: mockRouter,
        });

        expect(app.$options.name).toBe('SinglePageApplication');
      });
    });

    describe('when creating Vue instance with custom name', () => {
      it('creates Vue instance with custom name', () => {
        const app = initSinglePageApplication({
          name: 'CustomApp',
          el: mockEl,
          router: mockRouter,
        });

        expect(app.$options.name).toBe('CustomApp');
      });
    });

    describe('when rendering root component', () => {
      it('renders root component with  router-view', () => {
        createWrapper();

        expect(findRootComponent().exists()).toBe(true);
      });
    });

    describe('when setting up breadcrumbs injection', () => {
      beforeEach(() => {
        initSinglePageApplication({
          el: mockEl,
          router: mockRouter,
        });
      });

      it('calls the utility function for breadcrumbs', () => {
        expect(injectVueAppBreadcrumbs).toHaveBeenCalled();
      });
    });

    describe('when setting up router navigation watcher', () => {
      it('sets up router navigation watcher', () => {
        initSinglePageApplication({
          el: mockEl,
          router: mockRouter,
        });

        expect(mockRouter.beforeEach).toHaveBeenCalledWith(activeNavigationWatcher);
      });
    });

    describe('when passing provide data', () => {
      it('passes provide data to Vue instance', () => {
        const provide = {
          testData: 'test value',
          anotherProp: 42,
        };

        const app = initSinglePageApplication({
          el: mockEl,
          router: mockRouter,
          provide,
        });

        expect(app.$options.provide).toEqual(provide);
      });
    });

    describe('when passing propsData', () => {
      it('passes propsData to Vue instance', () => {
        const propsData = {
          random: 'prop',
        };

        const app = initSinglePageApplication({
          el: mockEl,
          router: mockRouter,
          propsData,
        });

        expect(app.$options.propsData).toEqual(propsData);
      });
    });
  });

  describe('Apollo provider setup', () => {
    describe('when apolloCacheConfig is provided', () => {
      it('creates Apollo provider', () => {
        const apolloCacheConfig = { cache: {} };

        const app = initSinglePageApplication({
          el: mockEl,
          router: mockRouter,
          apolloCacheConfig,
        });

        expect(app.$options.apolloProvider).toBeDefined();
      });
    });

    describe('when apolloCacheConfig is null', () => {
      it('does not create Apollo provider', () => {
        const app = initSinglePageApplication({
          el: mockEl,
          router: mockRouter,
          apolloCacheConfig: null,
        });

        expect(app.$options.apolloProvider).toBeUndefined();
      });
    });

    describe('when apolloCacheConfig is empty object', () => {
      it('creates Apollo provider with default config', () => {
        const app = initSinglePageApplication({
          el: mockEl,
          router: mockRouter,
          apolloCacheConfig: {},
        });

        expect(app.$options.apolloProvider).toBeDefined();
      });
    });

    describe('when passing additional options', () => {
      it('passes Pinia store through options', () => {
        const mockPiniaStore = {
          install: jest.fn(),
          state: jest.fn(() => ({})),
          scope: {},
        };

        const options = {
          pinia: mockPiniaStore,
        };

        const app = initSinglePageApplication({
          el: mockEl,
          router: mockRouter,
          options,
        });

        expect(app.$options.pinia).toBe(mockPiniaStore);
      });

      it('passes multiple additional options to Vue instance', () => {
        const customDirective = {
          bind() {},
          update() {},
        };

        const options = {
          directives: {
            customDirective,
          },
          methods: {
            customMethod() {
              return 'method result';
            },
          },
        };

        const app = initSinglePageApplication({
          el: mockEl,
          router: mockRouter,
          options,
        });

        expect(app.$options.directives.customDirective).toBe(customDirective);
        expect(app.$options.methods.customMethod).toBe(options.methods.customMethod);
      });
    });
  });
});
