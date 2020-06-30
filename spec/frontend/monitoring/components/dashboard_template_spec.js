import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import Dashboard from '~/monitoring/components/dashboard.vue';
import DashboardHeader from '~/monitoring/components/dashboard_header.vue';
import { createStore } from '~/monitoring/stores';
import { setupAllDashboards } from '../store_utils';
import { dashboardProps } from '../fixture_data';

jest.mock('~/lib/utils/url_utility');

describe('Dashboard template', () => {
  let wrapper;
  let store;
  let mock;

  beforeEach(() => {
    store = createStore({
      currentEnvironmentName: 'production',
    });
    mock = new MockAdapter(axios);

    setupAllDashboards(store);
  });

  afterEach(() => {
    mock.restore();
  });

  it('matches the default snapshot', () => {
    wrapper = shallowMount(Dashboard, {
      propsData: { ...dashboardProps },
      store,
      stubs: {
        DashboardHeader,
      },
    });

    expect(wrapper.element).toMatchSnapshot();
  });
});
