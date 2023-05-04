import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import { setHTMLFixture } from 'helpers/fixtures';
import { TEST_HOST } from 'helpers/test_constants';
import DashboardPanel from '~/monitoring/components/dashboard_panel.vue';
import MetricEmbed from '~/monitoring/components/embeds/metric_embed.vue';
import { groups, initialState, metricsData, metricsWithData } from './mock_data';

Vue.use(Vuex);

describe('MetricEmbed', () => {
  let wrapper;
  let store;
  let actions;
  let metricsWithDataGetter;

  function mountComponent() {
    wrapper = shallowMount(MetricEmbed, {
      store,
      propsData: {
        dashboardUrl: TEST_HOST,
      },
    });
  }

  beforeEach(() => {
    setHTMLFixture('<div class="layout-page"></div>');

    actions = {
      setInitialState: jest.fn(),
      setShowErrorBanner: jest.fn(),
      setTimeRange: jest.fn(),
      fetchDashboard: jest.fn(),
    };

    metricsWithDataGetter = jest.fn();

    store = new Vuex.Store({
      modules: {
        monitoringDashboard: {
          namespaced: true,
          actions,
          getters: {
            metricsWithData: () => metricsWithDataGetter,
          },
          state: initialState,
        },
      },
    });
  });

  afterEach(() => {
    metricsWithDataGetter.mockClear();
  });

  describe('no metrics are available yet', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('shows an empty state when no metrics are present', () => {
      expect(wrapper.find('.metrics-embed').exists()).toBe(true);
      expect(wrapper.findComponent(DashboardPanel).exists()).toBe(false);
    });
  });

  describe('metrics are available', () => {
    beforeEach(() => {
      store.state.monitoringDashboard.dashboard.panelGroups = groups;
      store.state.monitoringDashboard.dashboard.panelGroups[0].panels = metricsData;

      metricsWithDataGetter.mockReturnValue(metricsWithData);

      mountComponent();
    });

    it('calls actions to fetch data', () => {
      const expectedTimeRangePayload = expect.objectContaining({
        start: expect.any(String),
        end: expect.any(String),
      });

      expect(actions.setTimeRange).toHaveBeenCalledTimes(1);
      expect(actions.setTimeRange.mock.calls[0][1]).toEqual(expectedTimeRangePayload);

      expect(actions.fetchDashboard).toHaveBeenCalled();
    });

    it('shows a chart when metrics are present', () => {
      expect(wrapper.find('.metrics-embed').exists()).toBe(true);
      expect(wrapper.findComponent(DashboardPanel).exists()).toBe(true);
      expect(wrapper.findAllComponents(DashboardPanel).length).toBe(2);
    });

    it('includes groupId with dashboardUrl', () => {
      expect(wrapper.findComponent(DashboardPanel).props('groupId')).toBe(TEST_HOST);
    });
  });
});
