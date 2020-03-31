import { shallowMount } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';
import { setTestTimeout } from 'helpers/timeout';
import invalidUrl from '~/lib/utils/invalid_url';
import axios from '~/lib/utils/axios_utils';

import PanelType from '~/monitoring/components/panel_type.vue';
import EmptyChart from '~/monitoring/components/charts/empty_chart.vue';
import TimeSeriesChart from '~/monitoring/components/charts/time_series.vue';
import AnomalyChart from '~/monitoring/components/charts/anomaly.vue';
import {
  anomalyMockGraphData,
  graphDataPrometheusQueryRange,
  mockLogsHref,
  mockLogsPath,
  mockNamespace,
  mockNamespacedData,
  mockTimeRange,
} from 'jest/monitoring/mock_data';
import { createStore, monitoringDashboard } from '~/monitoring/stores';
import { createStore as createEmbedGroupStore } from '~/monitoring/stores/embed_group';

global.IS_EE = true;
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

  const createWrapper = props => {
    wrapper = shallowMount(PanelType, {
      propsData: {
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
    let glEmptyChart;
    // Deep clone object before modifying
    const graphDataNoResult = JSON.parse(JSON.stringify(graphDataPrometheusQueryRange));
    graphDataNoResult.metrics[0].result = [];

    beforeEach(() => {
      createWrapper({
        graphData: graphDataNoResult,
      });
    });

    afterEach(() => {
      wrapper.destroy();
    });

    describe('Empty Chart component', () => {
      beforeEach(() => {
        glEmptyChart = wrapper.find(EmptyChart);
      });

      it('renders the chart title', () => {
        expect(wrapper.find({ ref: 'graphTitle' }).text()).toBe(graphDataNoResult.title);
      });

      it('renders the no download csv link', () => {
        expect(wrapper.find({ ref: 'downloadCsvLink' }).exists()).toBe(false);
      });

      it('does not contain graph widgets', () => {
        expect(wrapper.find('.js-graph-widgets').exists()).toBe(false);
      });

      it('is a Vue instance', () => {
        expect(glEmptyChart.isVueInstance()).toBe(true);
      });

      it('it receives a graph title', () => {
        const props = glEmptyChart.props();

        expect(props.graphTitle).toBe(wrapper.vm.graphData.title);
      });
    });
  });

  describe('when graph data is available', () => {
    beforeEach(() => {
      createWrapper({
        graphData: graphDataPrometheusQueryRange,
      });
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('renders the chart title', () => {
      expect(wrapper.find({ ref: 'graphTitle' }).text()).toBe(graphDataPrometheusQueryRange.title);
    });

    it('contains graph widgets', () => {
      expect(wrapper.find('.js-graph-widgets').exists()).toBe(true);
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

    describe('Time Series Chart panel type', () => {
      it('is rendered', () => {
        expect(wrapper.find(TimeSeriesChart).isVueInstance()).toBe(true);
        expect(wrapper.find(TimeSeriesChart).exists()).toBe(true);
      });

      it('includes a default group id', () => {
        expect(wrapper.vm.groupId).toBe('panel-type-chart');
      });
    });

    describe('Anomaly Chart panel type', () => {
      beforeEach(() => {
        wrapper.setProps({
          graphData: anomalyMockGraphData,
        });
        return wrapper.vm.$nextTick();
      });

      it('is rendered with an anomaly chart', () => {
        expect(wrapper.find(AnomalyChart).isVueInstance()).toBe(true);
        expect(wrapper.find(AnomalyChart).exists()).toBe(true);
      });
    });
  });

  describe('Edit custom metric dropdown item', () => {
    const findEditCustomMetricLink = () => wrapper.find({ ref: 'editMetricLink' });

    beforeEach(() => {
      createWrapper({
        graphData: {
          ...graphDataPrometheusQueryRange,
        },
      });

      return wrapper.vm.$nextTick();
    });

    it('is not present if the panel is not a custom metric', () => {
      expect(findEditCustomMetricLink().exists()).toBe(false);
    });

    it('is present when the panel contains an edit_path property', () => {
      wrapper.setProps({
        graphData: {
          ...graphDataPrometheusQueryRange,
          metrics: [
            {
              ...graphDataPrometheusQueryRange.metrics[0],
              edit_path: '/root/kubernetes-gke-project/prometheus/metrics/23/edit',
            },
          ],
        },
      });

      return wrapper.vm.$nextTick(() => {
        expect(findEditCustomMetricLink().exists()).toBe(true);
      });
    });

    it('shows an "Edit metric" link for a panel with a single metric', () => {
      wrapper.setProps({
        graphData: {
          ...graphDataPrometheusQueryRange,
          metrics: [
            {
              ...graphDataPrometheusQueryRange.metrics[0],
              edit_path: '/root/kubernetes-gke-project/prometheus/metrics/23/edit',
            },
          ],
        },
      });

      return wrapper.vm.$nextTick(() => {
        expect(findEditCustomMetricLink().text()).toBe('Edit metric');
      });
    });

    it('shows an "Edit metrics" link for a panel with multiple metrics', () => {
      wrapper.setProps({
        graphData: {
          ...graphDataPrometheusQueryRange,
          metrics: [
            {
              ...graphDataPrometheusQueryRange.metrics[0],
              edit_path: '/root/kubernetes-gke-project/prometheus/metrics/23/edit',
            },
            {
              ...graphDataPrometheusQueryRange.metrics[0],
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
      createWrapper({
        graphData: graphDataPrometheusQueryRange,
      });
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
        graphData: graphDataPrometheusQueryRange,
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
      graphDataPrometheusQueryRange.y_label = 'metric';
      wrapper = shallowMount(PanelType, {
        propsData: {
          clipboardText: exampleText,
          graphData: graphDataPrometheusQueryRange,
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
        const header = `timestamp,${graphDataPrometheusQueryRange.y_label}`;
        const data = graphDataPrometheusQueryRange.metrics[0].result[0].values;
        const firstRow = `${data[0][0]},${data[0][1]}`;
        const secondRow = `${data[1][0]},${data[1][1]}`;

        expect(wrapper.vm.csvText).toBe(`${header}\r\n${firstRow}\r\n${secondRow}\r\n`);
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
          graphData: graphDataPrometheusQueryRange,
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
      expect(wrapper.find(TimeSeriesChart).isVueInstance()).toBe(true);
      expect(wrapper.find(TimeSeriesChart).exists()).toBe(true);
    });
  });
});
