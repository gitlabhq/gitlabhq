import { shallowMount } from '@vue/test-utils';
import DashboardPage from '~/monitoring/pages/dashboard_page.vue';
import Dashboard from '~/monitoring/components/dashboard.vue';
import { dashboardProps } from '../fixture_data';

describe('monitoring/pages/dashboard_page', () => {
  let wrapper;

  const buildWrapper = (props = {}) => {
    wrapper = shallowMount(DashboardPage, {
      propsData: {
        ...props,
      },
    });
  };

  const findDashboardComponent = () => wrapper.find(Dashboard);

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
