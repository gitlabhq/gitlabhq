import { shallowMount } from '@vue/test-utils';
import Dashboard from '~/monitoring/components/dashboard.vue';
import DashboardPage from '~/monitoring/pages/dashboard_page.vue';
import { createStore } from '~/monitoring/stores';
import { dashboardProps } from '../fixture_data';

describe('monitoring/pages/dashboard_page', () => {
  let wrapper;
  let store;
  let $route;

  const buildRouter = () => {
    const dashboard = {};
    $route = {
      params: { dashboard },
      query: { dashboard },
    };
  };

  const buildWrapper = (props = {}) => {
    wrapper = shallowMount(DashboardPage, {
      store,
      propsData: {
        ...props,
      },
      mocks: {
        $route,
      },
    });
  };

  const findDashboardComponent = () => wrapper.find(Dashboard);

  beforeEach(() => {
    buildRouter();
    store = createStore();
    jest.spyOn(store, 'dispatch').mockResolvedValue();
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  it('throws errors if dashboard props are not passed', () => {
    expect(() => buildWrapper()).toThrow('Missing required prop: "dashboardProps"');
  });

  it('renders the dashboard page with dashboard component', () => {
    buildWrapper({ dashboardProps });

    const allProps = {
      ...dashboardProps,
      // default props values
      rearrangePanelsAvailable: false,
      showHeader: true,
      showPanels: true,
      smallEmptyState: false,
    };

    expect(findDashboardComponent()).toExist();
    expect(allProps).toMatchObject(findDashboardComponent().props());
  });
});
