import { shallowMount } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';
import { setTestTimeout } from 'helpers/timeout';
import invalidUrl from '~/lib/utils/invalid_url';
import axios from '~/lib/utils/axios_utils';

import PanelType from '~/monitoring/components/panel_type.vue';
import {
  anomalyMockGraphData,
  mockLogsHref,
  mockLogsPath,
  mockNamespace,
  mockNamespacedData,
  mockTimeRange,
  singleStatMetricsResult,
  graphDataPrometheusQueryRangeMultiTrack,
  barMockData,
} from '../mock_data';

import { panelTypes } from '~/monitoring/constants';

import MonitorEmptyChart from '~/monitoring/components/charts/empty_chart.vue';
import MonitorTimeSeriesChart from '~/monitoring/components/charts/time_series.vue';
import MonitorAnomalyChart from '~/monitoring/components/charts/anomaly.vue';
import MonitorSingleStatChart from '~/monitoring/components/charts/single_stat.vue';
import MonitorHeatmapChart from '~/monitoring/components/charts/heatmap.vue';
import MonitorColumnChart from '~/monitoring/components/charts/column.vue';
import MonitorBarChart from '~/monitoring/components/charts/bar.vue';
import MonitorStackedColumnChart from '~/monitoring/components/charts/stacked_column.vue';

import { graphData, graphDataEmpty } from '../fixture_data';
import { createStore, monitoringDashboard } from '~/monitoring/stores';
import { createStore as createEmbedGroupStore } from '~/monitoring/stores/embed_group';

global.URL.createObjectURL = jest.fn();

const mocks = {
  $toast: {
    show: jest.fn(),
  },
};

describe('Panel Type component', () => {
  let axiosMock;
  let store;
  let state;
  let wrapper;

  const exampleText = 'example_text';

  const findCopyLink = () => wrapper.find({ ref: 'copyChartLink' });
  const findTimeChart = () => wrapper.find({ ref: 'timeChart' });
  const findTitle = () => wrapper.find({ ref: 'graphTitle' });
  const findContextualMenu = () => wrapper.find({ ref: 'contextualMenu' });

  const createWrapper = props => {
    wrapper = shallowMount(PanelType, {
      propsData: {
        graphData,
        ...props,
      },
      store,
      mocks,
    });
  };

  beforeEach(() => {
    setTestTimeout(1000);

    store = createStore();
    state = store.state.monitoringDashboard;

    axiosMock = new AxiosMockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.reset();
  });

  describe('When no graphData is available', () => {
    beforeEach(() => {
      createWrapper({
        graphData: graphDataEmpty,
      });
    });

    afterEach(() => {
      wrapper.destroy();
    });

    describe('Empty Chart component', () => {
      it('renders the chart title', () => {
        expect(findTitle().text()).toBe(graphDataEmpty.title);
      });

      it('renders the no download csv link', () => {
        expect(wrapper.find({ ref: 'downloadCsvLink' }).exists()).toBe(false);
      });

      it('does not contain graph widgets', () => {
        expect(findContextualMenu().exists()).toBe(false);
      });

      it('is a Vue instance', () => {
        expect(wrapper.find(MonitorEmptyChart).exists()).toBe(true);
        expect(wrapper.find(MonitorEmptyChart).isVueInstance()).toBe(true);
      });
    });
  });

  describe('when graph data is available', () => {
    beforeEach(() => {
      createWrapper();
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('renders the chart title', () => {
      expect(findTitle().text()).toBe(graphData.title);
    });

    it('contains graph widgets', () => {
      expect(findContextualMenu().exists()).toBe(true);
      expect(wrapper.find({ ref: 'downloadCsvLink' }).exists()).toBe(true);
    });

    it('sets no clipboard copy link on dropdown by default', () => {
      expect(findCopyLink().exists()).toBe(false);
    });

    it('should emit `timerange` event when a zooming in/out in a chart occcurs', () => {
      const timeRange = {
        start: '2020-01-01T00:00:00.000Z',
        end: '2020-01-01T01:00:00.000Z',
      };

      jest.spyOn(wrapper.vm, '$emit');

      findTimeChart().vm.$emit('datazoom', timeRange);

      return wrapper.vm.$nextTick(() => {
        expect(wrapper.vm.$emit).toHaveBeenCalledWith('timerangezoom', timeRange);
      });
    });

    it('includes a default group id', () => {
      expect(wrapper.vm.groupId).toBe('dashboard-panel');
    });

    describe('Supports different panel types', () => {
      const dataWithType = type => {
        return {
          ...graphData,
          type,
        };
      };

      it('empty chart is rendered for empty results', () => {
        createWrapper({ graphData: graphDataEmpty });
        expect(wrapper.find(MonitorEmptyChart).exists()).toBe(true);
        expect(wrapper.find(MonitorEmptyChart).isVueInstance()).toBe(true);
      });

      it('area chart is rendered by default', () => {
        createWrapper();
        expect(wrapper.find(MonitorTimeSeriesChart).exists()).toBe(true);
        expect(wrapper.find(MonitorTimeSeriesChart).isVueInstance()).toBe(true);
      });

      it.each`
        data                                       | component
        ${dataWithType(panelTypes.AREA_CHART)}     | ${MonitorTimeSeriesChart}
        ${dataWithType(panelTypes.LINE_CHART)}     | ${MonitorTimeSeriesChart}
        ${anomalyMockGraphData}                    | ${MonitorAnomalyChart}
        ${dataWithType(panelTypes.COLUMN)}         | ${MonitorColumnChart}
        ${dataWithType(panelTypes.STACKED_COLUMN)} | ${MonitorStackedColumnChart}
        ${singleStatMetricsResult}                 | ${MonitorSingleStatChart}
        ${graphDataPrometheusQueryRangeMultiTrack} | ${MonitorHeatmapChart}
        ${barMockData}                             | ${MonitorBarChart}
      `('type $data.type renders the expected component', ({ data, component }) => {
        createWrapper({ graphData: data });
        expect(wrapper.find(component).exists()).toBe(true);
        expect(wrapper.find(component).isVueInstance()).toBe(true);
      });
    });
  });

  describe('Edit custom metric dropdown item', () => {
    const findEditCustomMetricLink = () => wrapper.find({ ref: 'editMetricLink' });

    beforeEach(() => {
      createWrapper();

      return wrapper.vm.$nextTick();
    });

    it('is not present if the panel is not a custom metric', () => {
      expect(findEditCustomMetricLink().exists()).toBe(false);
    });

    it('is present when the panel contains an edit_path property', () => {
      wrapper.setProps({
        graphData: {
          ...graphData,
          metrics: [
            {
              ...graphData.metrics[0],
              edit_path: '/root/kubernetes-gke-project/prometheus/metrics/23/edit',
            },
          ],
        },
      });

      return wrapper.vm.$nextTick(() => {
        expect(findEditCustomMetricLink().exists()).toBe(true);
        expect(findEditCustomMetricLink().text()).toBe('Edit metric');
      });
    });

    it('shows an "Edit metrics" link for a panel with multiple metrics', () => {
      wrapper.setProps({
        graphData: {
          ...graphData,
          metrics: [
            {
              ...graphData.metrics[0],
              edit_path: '/root/kubernetes-gke-project/prometheus/metrics/23/edit',
            },
            {
              ...graphData.metrics[0],
              edit_path: '/root/kubernetes-gke-project/prometheus/metrics/23/edit',
            },
          ],
        },
      });

      return wrapper.vm.$nextTick(() => {
        expect(findEditCustomMetricLink().text()).toBe('Edit metrics');
      });
    });
  });

  describe('View Logs dropdown item', () => {
    const findViewLogsLink = () => wrapper.find({ ref: 'viewLogsLink' });

    beforeEach(() => {
      createWrapper();
      return wrapper.vm.$nextTick();
    });

    it('is not present by default', () =>
      wrapper.vm.$nextTick(() => {
        expect(findViewLogsLink().exists()).toBe(false);
      }));

    it('is not present if a time range is not set', () => {
      state.logsPath = mockLogsPath;
      state.timeRange = null;

      return wrapper.vm.$nextTick(() => {
        expect(findViewLogsLink().exists()).toBe(false);
      });
    });

    it('is not present if the logs path is default', () => {
      state.logsPath = invalidUrl;
      state.timeRange = mockTimeRange;

      return wrapper.vm.$nextTick(() => {
        expect(findViewLogsLink().exists()).toBe(false);
      });
    });

    it('is not present if the logs path is not set', () => {
      state.logsPath = null;
      state.timeRange = mockTimeRange;

      return wrapper.vm.$nextTick(() => {
        expect(findViewLogsLink().exists()).toBe(false);
      });
    });

    it('is present when logs path and time a range is present', () => {
      state.logsPath = mockLogsPath;
      state.timeRange = mockTimeRange;

      return wrapper.vm.$nextTick(() => {
        expect(findViewLogsLink().attributes('href')).toMatch(mockLogsHref);
      });
    });

    it('it is overriden when a datazoom event is received', () => {
      state.logsPath = mockLogsPath;
      state.timeRange = mockTimeRange;

      const zoomedTimeRange = {
        start: '2020-01-01T00:00:00.000Z',
        end: '2020-01-01T01:00:00.000Z',
      };

      findTimeChart().vm.$emit('datazoom', zoomedTimeRange);

      return wrapper.vm.$nextTick(() => {
        const start = encodeURIComponent(zoomedTimeRange.start);
        const end = encodeURIComponent(zoomedTimeRange.end);
        expect(findViewLogsLink().attributes('href')).toMatch(
          `${mockLogsPath}?start=${start}&end=${end}`,
        );
      });
    });
  });

  describe('when cliboard data is available', () => {
    const clipboardText = 'A value to copy.';

    beforeEach(() => {
      createWrapper({
        clipboardText,
      });
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('sets clipboard text on the dropdown', () => {
      expect(findCopyLink().exists()).toBe(true);
      expect(findCopyLink().element.dataset.clipboardText).toBe(clipboardText);
    });

    it('adds a copy button to the dropdown', () => {
      expect(findCopyLink().text()).toContain('Copy link to chart');
    });

    it('opens a toast on click', () => {
      findCopyLink().vm.$emit('click');

      expect(wrapper.vm.$toast.show).toHaveBeenCalled();
    });
  });

  describe('when downloading metrics data as CSV', () => {
    beforeEach(() => {
      wrapper = shallowMount(PanelType, {
        propsData: {
          clipboardText: exampleText,
          graphData: {
            y_label: 'metric',
            ...graphData,
          },
        },
        store,
      });
      return wrapper.vm.$nextTick();
    });

    afterEach(() => {
      wrapper.destroy();
    });

    describe('csvText', () => {
      it('converts metrics data from json to csv', () => {
        const header = `timestamp,${graphData.y_label}`;
        const data = graphData.metrics[0].result[0].values;
        const firstRow = `${data[0][0]},${data[0][1]}`;
        const secondRow = `${data[1][0]},${data[1][1]}`;

        expect(wrapper.vm.csvText).toMatch(`${header}\r\n${firstRow}\r\n${secondRow}\r\n`);
      });
    });

    describe('downloadCsv', () => {
      it('produces a link with a Blob', () => {
        expect(global.URL.createObjectURL).toHaveBeenLastCalledWith(expect.any(Blob));
        expect(global.URL.createObjectURL).toHaveBeenLastCalledWith(
          expect.objectContaining({
            size: wrapper.vm.csvText.length,
            type: 'text/plain',
          }),
        );
      });
    });
  });

  describe('when using dynamic modules', () => {
    const { mockDeploymentData, mockProjectPath } = mockNamespacedData;

    beforeEach(() => {
      store = createEmbedGroupStore();
      store.registerModule(mockNamespace, monitoringDashboard);
      store.state.embedGroup.modules.push(mockNamespace);

      wrapper = shallowMount(PanelType, {
        propsData: {
          graphData,
          namespace: mockNamespace,
        },
        store,
        mocks,
      });
    });

    it('handles namespaced time range and logs path state', () => {
      store.state[mockNamespace].timeRange = mockTimeRange;
      store.state[mockNamespace].logsPath = mockLogsPath;

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.find({ ref: 'viewLogsLink' }).attributes().href).toBe(mockLogsHref);
      });
    });

    it('handles namespaced deployment data state', () => {
      store.state[mockNamespace].deploymentData = mockDeploymentData;

      return wrapper.vm.$nextTick().then(() => {
        expect(findTimeChart().props().deploymentData).toEqual(mockDeploymentData);
      });
    });

    it('handles namespaced project path state', () => {
      store.state[mockNamespace].projectPath = mockProjectPath;

      return wrapper.vm.$nextTick().then(() => {
        expect(findTimeChart().props().projectPath).toBe(mockProjectPath);
      });
    });

    it('it renders a time series chart with no errors', () => {
      expect(wrapper.find(MonitorTimeSeriesChart).isVueInstance()).toBe(true);
      expect(wrapper.find(MonitorTimeSeriesChart).exists()).toBe(true);
    });
  });
});
