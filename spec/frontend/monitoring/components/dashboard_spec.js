import Vue from 'vue';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlToast, GlDropdownItem } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import Dashboard from '~/monitoring/components/dashboard.vue';
import GraphGroup from '~/monitoring/components/graph_group.vue';
import EmptyState from '~/monitoring/components/empty_state.vue';
import { timeWindows } from '~/monitoring/constants';
import * as types from '~/monitoring/stores/mutation_types';
import { createStore } from '~/monitoring/stores';
import axios from '~/lib/utils/axios_utils';

// TODO: replace with dynamic fixture
// https://gitlab.com/gitlab-org/gitlab-ce/issues/62785
import MonitoringMock, {
  metricsGroupsAPIResponse,
  mockApiEndpoint,
  environmentData,
  singleGroupResponse,
  dashboardGitResponse,
} from '../../../../spec/javascripts/monitoring/mock_data';

/* eslint-disable no-unused-vars */
/* eslint-disable no-undef */
// see https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/32571#note_211860465
function setupComponentStore(component) {
  component.$store.commit(
    `monitoringDashboard/${types.RECEIVE_METRICS_DATA_SUCCESS}`,
    metricsGroupsAPIResponse,
  );
  component.$store.commit(
    `monitoringDashboard/${types.SET_QUERY_RESULT}`,
    mockedQueryResultPayload,
  );
  component.$store.commit(
    `monitoringDashboard/${types.RECEIVE_ENVIRONMENTS_DATA_SUCCESS}`,
    environmentData,
  );
}

// Mock imported files while retaining the original behaviour
// See https://github.com/facebook/jest/issues/936#issuecomment-265074320
function mockMonitoringUtils() {
  const original = require.requireActual('~/monitoring/utils');
  return {
    ...original, // Pass down all the exported objects
    getTimeDiff: jest.spyOn(original, 'getTimeDiff'),
  };
}
jest.mock('~/monitoring/utils', () => mockMonitoringUtils());
const monitoringUtils = require.requireMock('~/monitoring/utils');

function mockUrlUtility() {
  const original = require.requireActual('~/lib/utils/url_utility');
  return {
    ...original, // Pass down all the exported objects
    getParameterValues: jest.spyOn(original, 'getParameterValues'),
  };
}
jest.mock('~/lib/utils/url_utility', () => mockUrlUtility());
const urlUtility = require.requireMock('~/lib/utils/url_utility');

const localVue = createLocalVue();
const propsData = {
  hasMetrics: false,
  documentationPath: '/path/to/docs',
  settingsPath: '/path/to/settings',
  clustersPath: '/path/to/clusters',
  tagsPath: '/path/to/tags',
  projectPath: '/path/to/project',
  metricsEndpoint: mockApiEndpoint,
  deploymentsEndpoint: null,
  emptyGettingStartedSvgPath: '/path/to/getting-started.svg',
  emptyLoadingSvgPath: '/path/to/loading.svg',
  emptyNoDataSvgPath: '/path/to/no-data.svg',
  emptyUnableToConnectSvgPath: '/path/to/unable-to-connect.svg',
  environmentsEndpoint: '/root/hello-prometheus/environments/35',
  currentEnvironmentName: 'production',
  customMetricsAvailable: false,
  customMetricsPath: '',
  validateQueryPath: '',
};

export default propsData;

describe('Dashboard', () => {
  let DashboardComponent;
  let mock;
  let store;
  let component;
  let mockGraphData;

  beforeEach(() => {
    setFixtures(`
      <div class="prometheus-graphs"></div>
      <div class="layout-page"></div>
    `);

    window.gon = {
      ...window.gon,
      ee: false,
    };

    store = createStore();
    mock = new MockAdapter(axios);
    DashboardComponent = Vue.extend(Dashboard);
  });

  afterEach(() => {
    if (component) {
      component.$destroy();
    }
    mock.restore();
  });

  describe('no metrics are available yet', () => {
    beforeEach(() => {
      component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: { ...propsData },
        store,
      });
    });

    it('shows a getting started empty state when no metrics are present', () => {
      expect(component.$el.querySelector('.prometheus-graphs')).toBe(null);
      expect(component.emptyState).toEqual('gettingStarted');
    });

    it('shows the environment selector', () => {
      expect(component.$el.querySelector('#monitor-environments-dropdown')).toBeTruthy();
    });
  });

  describe('no data found', () => {
    it('shows the environment selector dropdown', () => {
      component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: { ...propsData, showEmptyState: true },
        store,
      });

      expect(component.$el.querySelector('#monitor-environments-dropdown')).toBeTruthy();
    });
  });

  describe('requests information to the server', () => {
    beforeEach(() => {
      mock.onGet(mockApiEndpoint).reply(200, metricsGroupsAPIResponse);
    });

    it('shows up a loading state', done => {
      component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: { ...propsData, hasMetrics: true },
        store,
      });

      Vue.nextTick(() => {
        expect(component.emptyState).toEqual('loading');
        done();
      });
    });

    it('hides the group panels when showPanels is false', done => {
      const wrapper = shallowMount(DashboardComponent, {
        propsData: {
          ...propsData,
          hasMetrics: true,
          showPanels: false,
        },
        store,
        sync: false,
        localVue,
      });
      setImmediate(() => {
        expect(wrapper.find(EmptyState).exists()).toBe(false);
        expect(wrapper.find(GraphGroup).exists()).toBe(true);
        expect(wrapper.find(GraphGroup).props().showPanels).toBe(false);
        done();
      });
    });

    it('renders the environments dropdown with a number of environments', () => {
      const wrapper = shallowMount(DashboardComponent, {
        propsData: {
          ...propsData,
          hasMetrics: true,
          showPanels: false,
        },
        store,
      });

      store.commit(
        `monitoringDashboard/${types.RECEIVE_ENVIRONMENTS_DATA_SUCCESS}`,
        environmentData,
      );
      store.commit(
        `monitoringDashboard/${types.RECEIVE_METRICS_DATA_SUCCESS}`,
        singleGroupResponse,
      );

      Vue.nextTick(() => {
        const dropdownMenuEnvironments = wrapper
          .find('.js-environments-dropdown')
          .findAll(GlDropdownItem);

        expect(environmentData.length).toBeGreaterThan(0);
        expect(dropdownMenuEnvironments.length).toEqual(environmentData.length);
        dropdownMenuEnvironments.wrappers.forEach((value, index) => {
          expect(value.attributes('href')).toEqual(environmentData[index].metrics_path);
        });
      });
    });

    it('hides the environments dropdown list when there is no environments', () => {
      const wrapper = shallowMount(DashboardComponent, {
        propsData: {
          ...propsData,
          hasMetrics: true,
          showPanels: false,
        },
        store,
      });

      const findEnvironmentsDropdownItems = () => wrapper.find('#monitor-environments-wrapper');

      store.commit(`monitoringDashboard/${types.RECEIVE_ENVIRONMENTS_DATA_SUCCESS}`, []);
      store.commit(
        `monitoringDashboard/${types.RECEIVE_METRICS_DATA_SUCCESS}`,
        singleGroupResponse,
      );

      return Vue.nextTick(() => {
        expect(findEnvironmentsDropdownItems(wrapper).exists()).toEqual(false);
      });
    });

    it('renders the environments dropdown with a single active element', () => {
      const wrapper = shallowMount(DashboardComponent, {
        propsData: {
          ...propsData,
          hasMetrics: true,
          showPanels: false,
        },
        store,
        sync: false,
        localVue,
      });

      store.commit(
        `monitoringDashboard/${types.RECEIVE_ENVIRONMENTS_DATA_SUCCESS}`,
        environmentData,
      );
      store.commit(
        `monitoringDashboard/${types.RECEIVE_METRICS_DATA_SUCCESS}`,
        singleGroupResponse,
      );

      Vue.nextTick(() => {
        const activeDropdownMenuEnvironments = wrapper
          .find('#monitor-environments-dropdown')
          .findAll(GlDropdownItem)
          .filter(item => item.attributes('active') === 'true');

        expect(activeDropdownMenuEnvironments.length).toEqual(1);
      });
    });

    it('hides the dropdown', done => {
      component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: {
          ...propsData,
          hasMetrics: true,
          showPanels: false,
          environmentsEndpoint: '',
        },
        store,
      });

      Vue.nextTick(() => {
        const dropdownIsActiveElement = component.$el.querySelectorAll('.environments');

        expect(dropdownIsActiveElement.length).toEqual(0);
        done();
      });
    });

    it('renders the time window dropdown with a set of options', done => {
      const wrapper = shallowMount(DashboardComponent, {
        propsData: {
          ...propsData,
          hasMetrics: true,
          showPanels: false,
          sync: false,
        },
        store,
      });

      const numberOfTimeWindows = Object.keys(timeWindows).length;

      setImmediate(() => {
        const timeWindowDropdown = wrapper.find('.js-time-window-dropdown');
        const timeWindowDropdownEls = wrapper
          .find('.js-time-window-dropdown')
          .findAll(GlDropdownItem);

        expect(timeWindowDropdown.exists()).toBe(true);
        expect(timeWindowDropdownEls.length).toEqual(numberOfTimeWindows);

        done();
      });
    });

    it('fetches the metrics data with proper time window', () => {
      jest.spyOn(store, 'dispatch').mockImplementationOnce(() => {});

      store.commit(
        `monitoringDashboard/${types.RECEIVE_ENVIRONMENTS_DATA_SUCCESS}`,
        environmentData,
      );

      shallowMount(DashboardComponent, {
        propsData: {
          ...propsData,
          hasMetrics: true,
          showPanels: false,
        },
        store,
      });

      const defaultRange = monitoringUtils.getTimeDiff();
      return Vue.nextTick().then(() => {
        expect(store.dispatch).toHaveBeenCalledWith('monitoringDashboard/fetchData', defaultRange);
      });
    });

    it('shows a specific time window selected from the url params', done => {
      const start = 1564439536;
      const end = 1564441336;
      monitoringUtils.getTimeDiff.mockReturnValueOnce({
        start,
        end,
      });
      urlUtility.getParameterValues.mockImplementationOnce(param => {
        if (param === 'start') return [start];
        if (param === 'end') return [end];
        return [];
      });

      const wrapper = shallowMount(DashboardComponent, {
        propsData: {
          ...propsData,
          hasMetrics: true,
          showPanels: false,
        },
        store,
      });

      setImmediate(() => {
        const activeTimeWindowItems = wrapper
          .find('.js-time-window-dropdown')
          .findAll(GlDropdownItem)
          .filter(item => item.attributes('active') === 'true');

        expect(activeTimeWindowItems.length).toEqual(1);
        expect(activeTimeWindowItems.wrappers[0].text().trim()).toEqual('30 minutes');

        done();
      });
    });
  });

  describe('link to chart', () => {
    let wrapper;
    const currentDashboard = 'TEST_DASHBOARD';
    localVue.use(GlToast);
    const link = () => wrapper.find('.js-chart-link');
    const clipboardText = () => link().element.dataset.clipboardText;

    beforeEach(done => {
      mock.onGet(mockApiEndpoint).reply(200, metricsGroupsAPIResponse);

      wrapper = shallowMount(DashboardComponent, {
        localVue,
        propsData: { ...propsData, hasMetrics: true, currentDashboard },
        store,
      });

      setImmediate(() => {
        done();
      });
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('adds a copy button to the dropdown', () => {
      expect(link().text()).toContain('Generate link to chart');
    });

    it('contains a link to the dashboard', () => {
      expect(clipboardText()).toContain(`dashboard=${currentDashboard}`);
      expect(clipboardText()).toContain(`group=`);
      expect(clipboardText()).toContain(`title=`);
      expect(clipboardText()).toContain(`y_label=`);
    });

    it('undefined parameter is stripped', done => {
      wrapper.setProps({ currentDashboard: undefined });

      wrapper.vm.$nextTick(() => {
        expect(clipboardText()).not.toContain(`dashboard=`);
        expect(clipboardText()).toContain(`y_label=`);
        done();
      });
    });

    it('null parameter is stripped', done => {
      wrapper.setProps({ currentDashboard: null });

      wrapper.vm.$nextTick(() => {
        expect(clipboardText()).not.toContain(`dashboard=`);
        expect(clipboardText()).toContain(`y_label=`);
        done();
      });
    });

    it('creates a toast when clicked', () => {
      jest.spyOn(wrapper.vm.$toast, 'show').mockImplementation(() => {});

      link().vm.$emit('click');

      expect(wrapper.vm.$toast.show).toHaveBeenCalled();
    });
  });

  describe('when the window resizes', () => {
    beforeEach(() => {
      mock.onGet(mockApiEndpoint).reply(200, metricsGroupsAPIResponse);
    });

    it('sets elWidth to page width when the sidebar is resized', done => {
      component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: {
          ...propsData,
          hasMetrics: true,
          showPanels: false,
        },
        store,
      });

      expect(component.elWidth).toEqual(0);

      const pageLayoutEl = document.querySelector('.layout-page');
      pageLayoutEl.classList.add('page-with-icon-sidebar');

      Vue.nextTick()
        .then(() => {
          jest.advanceTimersByTime(1000);
          return Vue.nextTick();
        })
        .then(() => {
          expect(component.elWidth).toEqual(pageLayoutEl.clientWidth);
          done();
        })
        .catch(done.fail);
    });
  });

  describe('external dashboard link', () => {
    let wrapper;

    beforeEach(done => {
      mock.onGet(mockApiEndpoint).reply(200, metricsGroupsAPIResponse);

      wrapper = shallowMount(DashboardComponent, {
        propsData: {
          ...propsData,
          hasMetrics: true,
          showPanels: false,
          showTimeWindowDropdown: false,
          externalDashboardUrl: '/mockUrl',
        },
        store,
        sync: false,
        localVue,
      });

      setImmediate(done);
    });

    it('shows the link', () => {
      expect(wrapper.find('.js-external-dashboard-link').text()).toContain('View full dashboard');
    });
  });

  describe('Dashboard dropdown', () => {
    let wrapper;

    beforeEach(done => {
      mock.onGet(mockApiEndpoint).reply(200, metricsGroupsAPIResponse);

      wrapper = shallowMount(DashboardComponent, {
        propsData: { ...propsData, hasMetrics: true, showPanels: false },
        store,
        sync: false,
        localVue,
      });

      setImmediate(() => {
        store.dispatch('monitoringDashboard/setFeatureFlags', {
          prometheusEndpoint: false,
          multipleDashboardsEnabled: true,
        });

        store.commit(
          `monitoringDashboard/${types.RECEIVE_ENVIRONMENTS_DATA_SUCCESS}`,
          environmentData,
        );
        store.commit(
          `monitoringDashboard/${types.RECEIVE_METRICS_DATA_SUCCESS}`,
          singleGroupResponse,
        );

        store.commit(`monitoringDashboard/${types.SET_ALL_DASHBOARDS}`, dashboardGitResponse);
        done();
      });
    });

    it('shows the dashboard dropdown', () => {
      expect(wrapper.find('.js-dashboards-dropdown').exists()).toEqual(true);
    });
  });

  describe('when downloading metrics data as CSV', () => {
    beforeEach(() => {
      component = new DashboardComponent({
        propsData: {
          ...propsData,
        },
        store,
      });
      store.commit(
        `monitoringDashboard/${types.RECEIVE_METRICS_DATA_SUCCESS}`,
        MonitoringMock.data,
      );
      [mockGraphData] = component.$store.state.monitoringDashboard.groups[0].metrics;
    });

    describe('csvText', () => {
      it('converts metrics data from json to csv', () => {
        const header = `timestamp,${mockGraphData.y_label}`;
        const data = mockGraphData.queries[0].result[0].values;
        const firstRow = `${data[0][0]},${data[0][1]}`;

        expect(component.csvText(mockGraphData)).toContain(`${header}\r\n${firstRow}`);
      });
    });

    describe('downloadCsv', () => {
      let spy;

      beforeEach(() => {
        spy = jest.spyOn(window.URL, 'createObjectURL');
      });

      afterEach(() => {
        spy.mockRestore();
      });

      it('creates a string containing a URL that represents the object', () => {
        component.downloadCsv(mockGraphData);

        expect(spy).toHaveBeenCalled();
      });
    });
  });
});
