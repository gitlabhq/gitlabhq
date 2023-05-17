import { GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';
import Vuex from 'vuex';
import { nextTick } from 'vue';
import axios from '~/lib/utils/axios_utils';

import MonitorAnomalyChart from '~/monitoring/components/charts/anomaly.vue';
import MonitorBarChart from '~/monitoring/components/charts/bar.vue';
import MonitorColumnChart from '~/monitoring/components/charts/column.vue';
import MonitorEmptyChart from '~/monitoring/components/charts/empty_chart.vue';
import MonitorHeatmapChart from '~/monitoring/components/charts/heatmap.vue';
import MonitorSingleStatChart from '~/monitoring/components/charts/single_stat.vue';
import MonitorStackedColumnChart from '~/monitoring/components/charts/stacked_column.vue';
import MonitorTimeSeriesChart from '~/monitoring/components/charts/time_series.vue';
import DashboardPanel from '~/monitoring/components/dashboard_panel.vue';
import { panelTypes } from '~/monitoring/constants';

import { createStore, monitoringDashboard } from '~/monitoring/stores';
import { createStore as createEmbedGroupStore } from '~/monitoring/stores/embed_group';
import { dashboardProps, graphData, graphDataEmpty } from '../fixture_data';
import {
  anomalyGraphData,
  singleStatGraphData,
  heatmapGraphData,
  barGraphData,
} from '../graph_data';
import { mockNamespace, mockNamespacedData, mockTimeRange } from '../mock_data';

const mocks = {
  $toast: {
    show: jest.fn(),
  },
};

describe('Dashboard Panel', () => {
  let axiosMock;
  let store;
  let state;
  let wrapper;

  const exampleText = 'example_text';

  const findCopyLink = () => wrapper.findComponent({ ref: 'copyChartLink' });
  const findTimeChart = () => wrapper.findComponent({ ref: 'timeSeriesChart' });
  const findTitle = () => wrapper.findComponent({ ref: 'graphTitle' });
  const findCtxMenu = () => wrapper.findComponent({ ref: 'contextualMenu' });
  const findMenuItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findMenuItemByText = (text) => findMenuItems().filter((i) => i.text() === text);

  const createWrapper = (props, { mountFn = shallowMount, ...options } = {}) => {
    wrapper = mountFn(DashboardPanel, {
      propsData: {
        graphData,
        settingsPath: dashboardProps.settingsPath,
        ...props,
      },
      store,
      mocks,
      ...options,
    });
  };

  const mockGetterReturnValue = (getter, value) => {
    jest.spyOn(monitoringDashboard.getters, getter).mockReturnValue(value);
    store = new Vuex.Store({
      modules: {
        monitoringDashboard,
      },
    });
  };

  beforeEach(() => {
    store = createStore();
    state = store.state.monitoringDashboard;

    axiosMock = new AxiosMockAdapter(axios);

    jest.spyOn(URL, 'createObjectURL');
  });

  afterEach(() => {
    axiosMock.reset();
  });

  describe('Renders slots', () => {
    it('renders "topLeft" slot', () => {
      createWrapper(
        {},
        {
          slots: {
            'top-left': `<div class="top-left-content">OK</div>`,
          },
        },
      );

      expect(wrapper.find('.top-left-content').exists()).toBe(true);
      expect(wrapper.find('.top-left-content').text()).toBe('OK');
    });
  });

  describe('When no graphData is available', () => {
    beforeEach(() => {
      createWrapper({
        graphData: graphDataEmpty,
      });
    });

    it('renders the chart title', () => {
      expect(findTitle().text()).toBe(graphDataEmpty.title);
    });

    it('renders no download csv link', () => {
      expect(wrapper.findComponent({ ref: 'downloadCsvLink' }).exists()).toBe(false);
    });

    it('does not contain graph widgets', () => {
      expect(findCtxMenu().exists()).toBe(false);
    });

    it('The Empty Chart component is rendered and is a Vue instance', () => {
      expect(wrapper.findComponent(MonitorEmptyChart).exists()).toBe(true);
    });
  });

  describe('When graphData is null', () => {
    beforeEach(() => {
      createWrapper({
        graphData: null,
      });
    });

    it('renders no chart title', () => {
      expect(findTitle().text()).toBe('');
    });

    it('renders no download csv link', () => {
      expect(wrapper.findComponent({ ref: 'downloadCsvLink' }).exists()).toBe(false);
    });

    it('does not contain graph widgets', () => {
      expect(findCtxMenu().exists()).toBe(false);
    });

    it('The Empty Chart component is rendered and is a Vue instance', () => {
      expect(wrapper.findComponent(MonitorEmptyChart).exists()).toBe(true);
    });
  });

  describe('When graphData is available', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders the chart title', () => {
      expect(findTitle().text()).toBe(graphData.title);
    });

    it('contains graph widgets', () => {
      expect(findCtxMenu().exists()).toBe(true);
      expect(wrapper.findComponent({ ref: 'downloadCsvLink' }).exists()).toBe(true);
    });

    it('sets no clipboard copy link on dropdown by default', () => {
      expect(findCopyLink().exists()).toBe(false);
    });

    it('should emit `timerange` event when a zooming in/out in a chart occcurs', async () => {
      const timeRange = {
        start: '2020-01-01T00:00:00.000Z',
        end: '2020-01-01T01:00:00.000Z',
      };

      jest.spyOn(wrapper.vm, '$emit');

      findTimeChart().vm.$emit('datazoom', timeRange);

      await nextTick();
      expect(wrapper.vm.$emit).toHaveBeenCalledWith('timerangezoom', timeRange);
    });

    it('includes a default group id', () => {
      expect(wrapper.vm.groupId).toBe('dashboard-panel');
    });

    describe('Supports different panel types', () => {
      const dataWithType = (type) => {
        return {
          ...graphData,
          type,
        };
      };

      it('empty chart is rendered for empty results', () => {
        createWrapper({ graphData: graphDataEmpty });
        expect(wrapper.findComponent(MonitorEmptyChart).exists()).toBe(true);
      });

      it('area chart is rendered by default', () => {
        createWrapper();
        expect(wrapper.findComponent(MonitorTimeSeriesChart).exists()).toBe(true);
      });

      describe.each`
        data                                       | component                    | hasCtxMenu
        ${dataWithType(panelTypes.AREA_CHART)}     | ${MonitorTimeSeriesChart}    | ${true}
        ${dataWithType(panelTypes.LINE_CHART)}     | ${MonitorTimeSeriesChart}    | ${true}
        ${singleStatGraphData()}                   | ${MonitorSingleStatChart}    | ${true}
        ${anomalyGraphData()}                      | ${MonitorAnomalyChart}       | ${false}
        ${dataWithType(panelTypes.COLUMN)}         | ${MonitorColumnChart}        | ${false}
        ${dataWithType(panelTypes.STACKED_COLUMN)} | ${MonitorStackedColumnChart} | ${false}
        ${heatmapGraphData()}                      | ${MonitorHeatmapChart}       | ${false}
        ${barGraphData()}                          | ${MonitorBarChart}           | ${false}
      `('when $data.type data is provided', ({ data, component, hasCtxMenu }) => {
        const attrs = { attr1: 'attr1Value', attr2: 'attr2Value' };

        beforeEach(() => {
          createWrapper({ graphData: data }, { attrs });
        });

        it(`renders the chart component and binds attributes`, () => {
          expect(wrapper.findComponent(component).exists()).toBe(true);
          expect(wrapper.findComponent(component).attributes()).toMatchObject(attrs);
        });

        it(`contextual menu is ${hasCtxMenu ? '' : 'not '}shown`, () => {
          expect(findCtxMenu().exists()).toBe(hasCtxMenu);
        });
      });
    });

    describe('computed', () => {
      describe('fixedCurrentTimeRange', () => {
        it('returns fixed time for valid time range', async () => {
          state.timeRange = mockTimeRange;
          await nextTick();
          expect(findTimeChart().props('timeRange')).toEqual(
            expect.objectContaining({
              start: expect.any(String),
              end: expect.any(String),
            }),
          );
        });

        it.each`
          input           | output
          ${''}           | ${{}}
          ${undefined}    | ${{}}
          ${null}         | ${{}}
          ${'2020-12-03'} | ${{}}
        `('returns $output for invalid input like $input', async ({ input, output }) => {
          state.timeRange = input;
          await nextTick();
          expect(findTimeChart().props('timeRange')).toEqual(output);
        });
      });
    });
  });

  describe('Edit custom metric dropdown item', () => {
    const findEditCustomMetricLink = () => wrapper.findComponent({ ref: 'editMetricLink' });
    const mockEditPath = '/root/kubernetes-gke-project/prometheus/metrics/23/edit';

    beforeEach(async () => {
      createWrapper();
      await nextTick();
    });

    it('is not present if the panel is not a custom metric', () => {
      expect(findEditCustomMetricLink().exists()).toBe(false);
    });

    it('is present when the panel contains an edit_path property', async () => {
      wrapper.setProps({
        graphData: {
          ...graphData,
          metrics: [
            {
              ...graphData.metrics[0],
              edit_path: mockEditPath,
            },
          ],
        },
      });

      await nextTick();
      expect(findEditCustomMetricLink().exists()).toBe(true);
      expect(findEditCustomMetricLink().text()).toBe('Edit metric');
      expect(findEditCustomMetricLink().attributes('href')).toBe(mockEditPath);
    });

    it('shows an "Edit metrics" link pointing to settingsPath for a panel with multiple metrics', async () => {
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

      await nextTick();
      expect(findEditCustomMetricLink().text()).toBe('Edit metrics');
      expect(findEditCustomMetricLink().attributes('href')).toBe(dashboardProps.settingsPath);
    });
  });

  describe('when clipboard data is available', () => {
    const clipboardText = 'A value to copy.';

    beforeEach(() => {
      createWrapper({
        clipboardText,
      });
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

  describe('when clipboard data is not available', () => {
    it('there is no "copy to clipboard" link for a null value', () => {
      createWrapper({ clipboardText: null });
      expect(findCopyLink().exists()).toBe(false);
    });

    it('there is no "copy to clipboard" link for an empty value', () => {
      createWrapper({ clipboardText: '' });
      expect(findCopyLink().exists()).toBe(false);
    });
  });

  describe('when downloading metrics data as CSV', () => {
    beforeEach(async () => {
      wrapper = shallowMount(DashboardPanel, {
        propsData: {
          clipboardText: exampleText,
          settingsPath: dashboardProps.settingsPath,
          graphData: {
            y_label: 'metric',
            ...graphData,
          },
        },
        store,
      });
      await nextTick();
    });

    describe('csvText', () => {
      it('converts metrics data from json to csv', () => {
        const header = `timestamp,"${graphData.y_label} > ${graphData.metrics[0].label}"`;
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

      createWrapper({ namespace: mockNamespace });
    });

    it('handles namespaced deployment data state', async () => {
      store.state[mockNamespace].deploymentData = mockDeploymentData;

      await nextTick();
      expect(findTimeChart().props().deploymentData).toEqual(mockDeploymentData);
    });

    it('handles namespaced project path state', async () => {
      store.state[mockNamespace].projectPath = mockProjectPath;

      await nextTick();
      expect(findTimeChart().props().projectPath).toBe(mockProjectPath);
    });

    it('renders a time series chart with no errors', () => {
      expect(wrapper.findComponent(MonitorTimeSeriesChart).exists()).toBe(true);
    });
  });

  describe('panel timezone', () => {
    it('displays a time chart in local timezone', () => {
      createWrapper();
      expect(findTimeChart().props('timezone')).toBe('LOCAL');
    });

    it('displays a heatmap in local timezone', () => {
      createWrapper({ graphData: heatmapGraphData() });
      expect(wrapper.findComponent(MonitorHeatmapChart).props('timezone')).toBe('LOCAL');
    });

    describe('when timezone is set to UTC', () => {
      beforeEach(() => {
        store = createStore({ dashboardTimezone: 'UTC' });
      });

      it('displays a time chart with UTC', () => {
        createWrapper();
        expect(findTimeChart().props('timezone')).toBe('UTC');
      });

      it('displays a heatmap with UTC', () => {
        createWrapper({ graphData: heatmapGraphData() });
        expect(wrapper.findComponent(MonitorHeatmapChart).props('timezone')).toBe('UTC');
      });
    });
  });

  describe('Expand to full screen', () => {
    const findExpandBtn = () => wrapper.findComponent({ ref: 'expandBtn' });

    describe('when there is no @expand listener', () => {
      it('does not show `View full screen` option', () => {
        createWrapper();
        expect(findExpandBtn().exists()).toBe(false);
      });
    });

    describe('when there is an @expand listener', () => {
      beforeEach(() => {
        createWrapper({}, { listeners: { expand: () => {} } });
      });

      it('shows the `expand` option', () => {
        expect(findExpandBtn().exists()).toBe(true);
      });

      it('emits the `expand` event', () => {
        const preventDefault = jest.fn();
        findExpandBtn().vm.$emit('click', { preventDefault });
        expect(wrapper.emitted('expand')).toHaveLength(1);
        expect(preventDefault).toHaveBeenCalled();
      });
    });
  });

  describe('When graphData contains links', () => {
    const findManageLinksItem = () => wrapper.findComponent({ ref: 'manageLinksItem' });
    const mockLinks = [
      {
        url: 'https://example.com',
        title: 'Example 1',
      },
      {
        url: 'https://gitlab.com',
        title: 'Example 2',
      },
    ];
    const createWrapperWithLinks = (links = mockLinks) => {
      createWrapper({
        graphData: {
          ...graphData,
          links,
        },
      });
    };

    it('custom links are shown', () => {
      createWrapperWithLinks();

      mockLinks.forEach(({ url, title }) => {
        const link = findMenuItemByText(title).at(0);

        expect(link.exists()).toBe(true);
        expect(link.attributes('href')).toBe(url);
      });
    });

    it("custom links don't show unsecure content", () => {
      createWrapperWithLinks([
        {
          title: '<script>alert("XSS")</script>',
          url: 'http://example.com',
        },
      ]);

      expect(findMenuItems().at(1).element.innerHTML).toBe(
        '&lt;script&gt;alert("XSS")&lt;/script&gt;',
      );
    });

    it("custom links don't show unsecure href attributes", () => {
      const title = 'Owned!';

      createWrapperWithLinks([
        {
          title,
          // eslint-disable-next-line no-script-url
          url: 'javascript:alert("Evil")',
        },
      ]);

      const link = findMenuItemByText(title).at(0);
      expect(link.attributes('href')).toBe('#');
    });

    it('when an editable dashboard is selected, shows `Manage chart links` link to the blob path', () => {
      const editUrl = '/edit';
      mockGetterReturnValue('selectedDashboard', {
        can_edit: true,
        project_blob_path: editUrl,
      });
      createWrapperWithLinks();

      expect(findManageLinksItem().exists()).toBe(true);
      expect(findManageLinksItem().attributes('href')).toBe(editUrl);
    });

    it('when no dashboard is selected, does not show `Manage chart links`', () => {
      mockGetterReturnValue('selectedDashboard', null);
      createWrapperWithLinks();

      expect(findManageLinksItem().exists()).toBe(false);
    });

    it('when non-editable dashboard is selected, does not show `Manage chart links`', () => {
      const editUrl = '/edit';
      mockGetterReturnValue('selectedDashboard', {
        can_edit: false,
        project_blob_path: editUrl,
      });
      createWrapperWithLinks();

      expect(findManageLinksItem().exists()).toBe(false);
    });
  });

  describe('Runbook url', () => {
    const findRunbookLinks = () => wrapper.findAll('[data-testid="runbookLink"]');

    beforeEach(() => {
      mockGetterReturnValue('metricsSavedToDb', []);
    });

    it('does not show a runbook link when alerts are not present', () => {
      createWrapper();

      expect(findRunbookLinks().length).toBe(0);
    });
  });
});
