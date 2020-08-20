import { shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import { DASHBOARD_PAGE, PANEL_NEW_PAGE } from '~/monitoring/router/constants';
import { createStore } from '~/monitoring/stores';
import DashboardPanelBuilder from '~/monitoring/components/dashboard_panel_builder.vue';

import PanelNewPage from '~/monitoring/pages/panel_new_page.vue';

const dashboard = 'dashboard.yml';

// Button stub that can accept `to` as router links do
// https://bootstrap-vue.org/docs/components/button#comp-ref-b-button-props
const GlButtonStub = {
  extends: GlButton,
  props: {
    to: [String, Object],
  },
};

describe('monitoring/pages/panel_new_page', () => {
  let store;
  let wrapper;
  let $route;
  let $router;

  const mountComponent = (propsData = {}, route) => {
    $route = route ?? { name: PANEL_NEW_PAGE, params: { dashboard } };
    $router = {
      push: jest.fn(),
    };

    wrapper = shallowMount(PanelNewPage, {
      propsData,
      store,
      stubs: {
        GlButton: GlButtonStub,
      },
      mocks: {
        $router,
        $route,
      },
    });
  };

  const findBackButton = () => wrapper.find(GlButtonStub);
  const findPanelBuilder = () => wrapper.find(DashboardPanelBuilder);

  beforeEach(() => {
    store = createStore();
    mountComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('back to dashboard button', () => {
    it('is rendered', () => {
      expect(findBackButton().exists()).toBe(true);
      expect(findBackButton().props('icon')).toBe('go-back');
    });

    it('links back to the dashboard', () => {
      expect(findBackButton().props('to')).toEqual({
        name: DASHBOARD_PAGE,
        params: { dashboard },
      });
    });

    it('links back to the dashboard while preserving query params', () => {
      $route = {
        name: PANEL_NEW_PAGE,
        params: { dashboard },
        query: { another: 'param' },
      };

      mountComponent({}, $route);

      expect(findBackButton().props('to')).toEqual({
        name: DASHBOARD_PAGE,
        params: { dashboard },
        query: { another: 'param' },
      });
    });
  });

  describe('dashboard panel builder', () => {
    it('is rendered', () => {
      expect(findPanelBuilder().exists()).toBe(true);
    });
  });

  describe('page routing', () => {
    it('route is not updated by default', () => {
      expect($router.push).not.toHaveBeenCalled();
    });
  });
});
