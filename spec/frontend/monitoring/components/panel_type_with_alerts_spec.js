import Vuex from 'vuex';
import { shallowMount } from '@vue/test-utils';
import { GlDropdownItem } from '@gitlab/ui';
import { monitoringDashboard } from '~/monitoring/stores';
import PanelType from '~/monitoring/components/panel_type_with_alerts.vue';
import AlertWidget from '~/monitoring/components/alert_widget.vue';
import { graphData } from 'jest/monitoring/fixture_data';

global.URL.createObjectURL = jest.fn();

describe('Panel Type', () => {
  let store;
  let wrapper;

  const setMetricsSavedToDb = val =>
    monitoringDashboard.getters.metricsSavedToDb.mockReturnValue(val);
  const findAlertsWidget = () => wrapper.find(AlertWidget);
  const findMenuItemAlert = () =>
    wrapper.findAll(GlDropdownItem).filter(i => i.text() === 'Alerts');

  const mockPropsData = {
    graphData,
    clipboardText: 'example_text',
    alertsEndpoint: '/endpoint',
    prometheusAlertsAvailable: true,
  };

  const createWrapper = propsData => {
    wrapper = shallowMount(PanelType, {
      propsData: {
        ...mockPropsData,
        ...propsData,
      },
      store,
    });
  };

  beforeEach(() => {
    jest.spyOn(monitoringDashboard.getters, 'metricsSavedToDb').mockReturnValue([]);

    store = new Vuex.Store({
      modules: {
        monitoringDashboard,
      },
    });
  });

  describe('panel type alerts', () => {
    describe.each`
      desc                                           | metricsSavedToDb                   | propsData                               | isShown
      ${'with license and no metrics in db'}         | ${[]}                              | ${{}}                                   | ${false}
      ${'with license and related metrics in db'}    | ${[graphData.metrics[0].metricId]} | ${{}}                                   | ${true}
      ${'without license and related metrics in db'} | ${[graphData.metrics[0].metricId]} | ${{ prometheusAlertsAvailable: false }} | ${false}
      ${'with license and unrelated metrics in db'}  | ${['another_metric_id']}           | ${{}}                                   | ${false}
    `('$desc', ({ metricsSavedToDb, isShown, propsData }) => {
      const showsDesc = isShown ? 'shows' : 'does not show';

      beforeEach(() => {
        setMetricsSavedToDb(metricsSavedToDb);
        createWrapper(propsData);
        return wrapper.vm.$nextTick();
      });

      it(`${showsDesc} alert widget`, () => {
        expect(findAlertsWidget().exists()).toBe(isShown);
      });

      it(`${showsDesc} alert configuration`, () => {
        expect(findMenuItemAlert().exists()).toBe(isShown);
      });
    });
  });
});
