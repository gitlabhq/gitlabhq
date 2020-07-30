import { shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import { DASHBOARD_PAGE } from '~/monitoring/router/constants';
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
  let wrapper;
  let $route;

  const mountComponent = (propsData = {}, routeParams = { dashboard }) => {
    $route = {
      params: routeParams,
    };

    wrapper = shallowMount(PanelNewPage, {
      propsData,
      stubs: {
        GlButton: GlButtonStub,
      },
      mocks: {
        $route,
      },
    });
  };

  const findBackButton = () => wrapper.find(GlButtonStub);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('back to dashboard button', () => {
    it('is rendered', () => {
      mountComponent();
      expect(findBackButton().exists()).toBe(true);
      expect(findBackButton().props('icon')).toBe('go-back');
    });

    it('links back to the dashboard', () => {
      const dashboardLocation = {
        name: DASHBOARD_PAGE,
        params: { dashboard },
      };

      expect(findBackButton().props('to')).toEqual(dashboardLocation);
    });
  });
});
