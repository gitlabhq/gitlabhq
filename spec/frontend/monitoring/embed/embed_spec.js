import { createLocalVue, shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';
import Embed from '~/monitoring/components/embed.vue';
import MonitorAreaChart from '~/monitoring/components/charts/area.vue';
import { TEST_HOST } from 'helpers/test_constants';
import { groups, initialState, metricsData, metricsWithData } from './mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Embed', () => {
  let wrapper;
  let store;
  let actions;

  function mountComponent() {
    wrapper = shallowMount(Embed, {
      localVue,
      store,
      propsData: {
        dashboardUrl: TEST_HOST,
      },
    });
  }

  beforeEach(() => {
    actions = {
      setFeatureFlags: () => {},
      setShowErrorBanner: () => {},
      setEndpoints: () => {},
      fetchMetricsData: () => {},
    };

    store = new Vuex.Store({
      modules: {
        monitoringDashboard: {
          namespaced: true,
          actions,
          state: initialState,
        },
      },
    });
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
  });

  describe('no metrics are available yet', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('shows an empty state when no metrics are present', () => {
      expect(wrapper.find('.metrics-embed').exists()).toBe(true);
      expect(wrapper.find(MonitorAreaChart).exists()).toBe(false);
    });
  });

  describe('metrics are available', () => {
    beforeEach(() => {
      store.state.monitoringDashboard.groups = groups;
      store.state.monitoringDashboard.groups[0].metrics = metricsData;
      store.state.monitoringDashboard.metricsWithData = metricsWithData;

      mountComponent();
    });

    it('shows a chart when metrics are present', () => {
      wrapper.setProps({});
      expect(wrapper.find('.metrics-embed').exists()).toBe(true);
      expect(wrapper.find(MonitorAreaChart).exists()).toBe(true);
      expect(wrapper.findAll(MonitorAreaChart).length).toBe(2);
    });
  });
});
