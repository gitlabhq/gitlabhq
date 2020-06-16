import { shallowMount } from '@vue/test-utils';
import DashboardPage from '~/monitoring/pages/dashboard_page.vue';
import Dashboard from '~/monitoring/components/dashboard.vue';
import { propsData } from '../mock_data';

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
    buildWrapper({ dashboardProps: propsData });

    expect(findDashboardComponent().props()).toMatchObject(propsData);
    expect(findDashboardComponent()).toExist();
  });
});
