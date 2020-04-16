import { shallowMount, mount } from '@vue/test-utils';
import { GlDropdownItem, GlDeprecatedButton } from '@gitlab/ui';
import VueDraggable from 'vuedraggable';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import statusCodes from '~/lib/utils/http_status';
import { metricStates } from '~/monitoring/constants';
import Dashboard from '~/monitoring/components/dashboard.vue';

import DateTimePicker from '~/vue_shared/components/date_time_picker/date_time_picker.vue';
import DashboardsDropdown from '~/monitoring/components/dashboards_dropdown.vue';
import GroupEmptyState from '~/monitoring/components/group_empty_state.vue';
import PanelType from 'ee_else_ce/monitoring/components/panel_type.vue';
import { createStore } from '~/monitoring/stores';
import * as types from '~/monitoring/stores/mutation_types';
import { setupStoreWithDashboard, setMetricResult, setupStoreWithData } from '../store_utils';
import { environmentData, dashboardGitResponse, propsData } from '../mock_data';
import { metricsDashboardViewModel, metricsDashboardPanelCount } from '../fixture_data';

describe('Dashboard', () => {
  let store;
  let wrapper;
  let mock;

  const findEnvironmentsDropdown = () => wrapper.find({ ref: 'monitorEnvironmentsDropdown' });
  const findAllEnvironmentsDropdownItems = () => findEnvironmentsDropdown().findAll(GlDropdownItem);
  const setSearchTerm = searchTerm => {
    wrapper.vm.$store.commit(`monitoringDashboard/${types.SET_ENVIRONMENTS_FILTER}`, searchTerm);
  };

  const createShallowWrapper = (props = {}, options = {}) => {
    wrapper = shallowMount(Dashboard, {
      propsData: { ...propsData, ...props },
      methods: {
        fetchData: jest.fn(),
      },
      store,
      ...options,
    });
  };

  const createMountedWrapper = (props = {}, options = {}) => {
    wrapper = mount(Dashboard, {
      propsData: { ...propsData, ...props },
      methods: {
        fetchData: jest.fn(),
      },
      store,
      ...options,
    });
  };

  beforeEach(() => {
    store = createStore();
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
    mock.restore();
  });

  describe('no metrics are available yet', () => {
    beforeEach(() => {
      jest.spyOn(store, 'dispatch');
      createShallowWrapper();
    });

    it('shows the environment selector', () => {
      expect(findEnvironmentsDropdown().exists()).toBe(true);
    });

    it('sets initial state', () => {
      expect(store.dispatch).toHaveBeenCalledWith('monitoringDashboard/setInitialState', {
        currentDashboard: '',
        currentEnvironmentName: 'production',
        dashboardEndpoint: 'https://invalid',
        dashboardsEndpoint: 'https://invalid',
        deploymentsEndpoint: null,
        logsPath: '/path/to/logs',
        metricsEndpoint: 'http://test.host/monitoring/mock',
        projectPath: '/path/to/project',
      });
    });
  });

  describe('no data found', () => {
    beforeEach(() => {
      createShallowWrapper();

      return wrapper.vm.$nextTick();
    });

    it('shows the environment selector dropdown', () => {
      expect(findEnvironmentsDropdown().exists()).toBe(true);
    });
  });

  describe('request information to the server', () => {
    it('calls to set time range and fetch data', () => {
      jest.spyOn(store, 'dispatch');

      createShallowWrapper({ hasMetrics: true }, { methods: {} });

      return wrapper.vm.$nextTick().then(() => {
        expect(store.dispatch).toHaveBeenCalledWith(
          'monitoringDashboard/setTimeRange',
          expect.any(Object),
        );

        expect(store.dispatch).toHaveBeenCalledWith('monitoringDashboard/fetchData', undefined);
      });
    });

    it('shows up a loading state', () => {
      createShallowWrapper({ hasMetrics: true }, { methods: {} });

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.vm.emptyState).toEqual('loading');
      });
    });

    it('hides the group panels when showPanels is false', () => {
      createMountedWrapper(
        { hasMetrics: true, showPanels: false },
        { stubs: ['graph-group', 'panel-type'] },
      );

      setupStoreWithData(wrapper.vm.$store);

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.vm.showEmptyState).toEqual(false);
        expect(wrapper.findAll('.prometheus-panel')).toHaveLength(0);
      });
    });

    it('fetches the metrics data with proper time window', () => {
      jest.spyOn(store, 'dispatch');

      createMountedWrapper({ hasMetrics: true }, { stubs: ['graph-group', 'panel-type'] });

      wrapper.vm.$store.commit(
        `monitoringDashboard/${types.RECEIVE_ENVIRONMENTS_DATA_SUCCESS}`,
        environmentData,
      );

      return wrapper.vm.$nextTick().then(() => {
        expect(store.dispatch).toHaveBeenCalled();
      });
    });
  });

  describe('when all requests have been commited by the store', () => {
    beforeEach(() => {
      createMountedWrapper({ hasMetrics: true }, { stubs: ['graph-group', 'panel-type'] });

      setupStoreWithData(wrapper.vm.$store);

      return wrapper.vm.$nextTick();
    });

    it('renders the environments dropdown with a number of environments', () => {
      expect(findAllEnvironmentsDropdownItems().length).toEqual(environmentData.length);

      findAllEnvironmentsDropdownItems().wrappers.forEach((itemWrapper, index) => {
        const anchorEl = itemWrapper.find('a');
        if (anchorEl.exists() && environmentData[index].metrics_path) {
          const href = anchorEl.attributes('href');
          expect(href).toBe(environmentData[index].metrics_path);
        }
      });
    });

    it('renders the environments dropdown with a single active element', () => {
      const activeItem = findAllEnvironmentsDropdownItems().wrappers.filter(itemWrapper =>
        itemWrapper.find('.active').exists(),
      );

      expect(activeItem.length).toBe(1);
    });
  });

  it('hides the environments dropdown list when there is no environments', () => {
    createMountedWrapper({ hasMetrics: true }, { stubs: ['graph-group', 'panel-type'] });

    setupStoreWithDashboard(wrapper.vm.$store);

    return wrapper.vm.$nextTick().then(() => {
      expect(findAllEnvironmentsDropdownItems()).toHaveLength(0);
    });
  });

  it('renders the datetimepicker dropdown', () => {
    createMountedWrapper({ hasMetrics: true }, { stubs: ['graph-group', 'panel-type'] });

    setupStoreWithData(wrapper.vm.$store);

    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.find(DateTimePicker).exists()).toBe(true);
    });
  });

  it('renders the refresh dashboard button', () => {
    createMountedWrapper({ hasMetrics: true }, { stubs: ['graph-group', 'panel-type'] });

    setupStoreWithData(wrapper.vm.$store);

    return wrapper.vm.$nextTick().then(() => {
      const refreshBtn = wrapper.findAll({ ref: 'refreshDashboardBtn' });

      expect(refreshBtn).toHaveLength(1);
      expect(refreshBtn.is(GlDeprecatedButton)).toBe(true);
    });
  });

  describe('when one of the metrics is missing', () => {
    beforeEach(() => {
      createShallowWrapper({ hasMetrics: true });

      const { $store } = wrapper.vm;

      setupStoreWithDashboard($store);
      setMetricResult({ $store, result: [], panel: 2 });

      return wrapper.vm.$nextTick();
    });

    it('shows a group empty area', () => {
      const emptyGroup = wrapper.findAll({ ref: 'empty-group' });

      expect(emptyGroup).toHaveLength(1);
      expect(emptyGroup.is(GroupEmptyState)).toBe(true);
    });

    it('group empty area displays a NO_DATA state', () => {
      expect(
        wrapper
          .findAll({ ref: 'empty-group' })
          .at(0)
          .props('selectedState'),
      ).toEqual(metricStates.NO_DATA);
    });
  });

  describe('searchable environments dropdown', () => {
    beforeEach(() => {
      createMountedWrapper(
        { hasMetrics: true },
        {
          attachToDocument: true,
          stubs: ['graph-group', 'panel-type'],
        },
      );

      setupStoreWithData(wrapper.vm.$store);

      return wrapper.vm.$nextTick();
    });

    it('renders a search input', () => {
      expect(wrapper.find({ ref: 'monitorEnvironmentsDropdownSearch' }).exists()).toBe(true);
    });

    it('renders dropdown items', () => {
      findAllEnvironmentsDropdownItems().wrappers.forEach((itemWrapper, index) => {
        const anchorEl = itemWrapper.find('a');
        if (anchorEl.exists()) {
          expect(anchorEl.text()).toBe(environmentData[index].name);
        }
      });
    });

    it('filters rendered dropdown items', () => {
      const searchTerm = 'production';
      const resultEnvs = environmentData.filter(({ name }) => name.indexOf(searchTerm) !== -1);
      setSearchTerm(searchTerm);

      return wrapper.vm.$nextTick().then(() => {
        expect(findAllEnvironmentsDropdownItems().length).toEqual(resultEnvs.length);
      });
    });

    it('does not filter dropdown items if search term is empty string', () => {
      const searchTerm = '';
      setSearchTerm(searchTerm);

      return wrapper.vm.$nextTick(() => {
        expect(findAllEnvironmentsDropdownItems().length).toEqual(environmentData.length);
      });
    });

    it("shows error message if search term doesn't match", () => {
      const searchTerm = 'does-not-exist';
      setSearchTerm(searchTerm);

      return wrapper.vm.$nextTick(() => {
        expect(wrapper.find({ ref: 'monitorEnvironmentsDropdownMsg' }).isVisible()).toBe(true);
      });
    });

    it('shows loading element when environments fetch is still loading', () => {
      wrapper.vm.$store.commit(`monitoringDashboard/${types.REQUEST_ENVIRONMENTS_DATA}`);

      return wrapper.vm
        .$nextTick()
        .then(() => {
          expect(wrapper.find({ ref: 'monitorEnvironmentsDropdownLoading' }).exists()).toBe(true);
        })
        .then(() => {
          wrapper.vm.$store.commit(
            `monitoringDashboard/${types.RECEIVE_ENVIRONMENTS_DATA_SUCCESS}`,
            environmentData,
          );
        })
        .then(() => {
          expect(wrapper.find({ ref: 'monitorEnvironmentsDropdownLoading' }).exists()).toBe(false);
        });
    });
  });

  describe('drag and drop function', () => {
    const findDraggables = () => wrapper.findAll(VueDraggable);
    const findEnabledDraggables = () => findDraggables().filter(f => !f.attributes('disabled'));
    const findDraggablePanels = () => wrapper.findAll('.js-draggable-panel');
    const findRearrangeButton = () => wrapper.find('.js-rearrange-button');

    beforeEach(() => {
      createShallowWrapper({ hasMetrics: true });

      setupStoreWithData(wrapper.vm.$store);

      return wrapper.vm.$nextTick();
    });

    it('wraps vuedraggable', () => {
      expect(findDraggablePanels().exists()).toBe(true);
      expect(findDraggablePanels().length).toEqual(metricsDashboardPanelCount);
    });

    it('is disabled by default', () => {
      expect(findRearrangeButton().exists()).toBe(false);
      expect(findEnabledDraggables().length).toBe(0);
    });

    describe('when rearrange is enabled', () => {
      beforeEach(() => {
        wrapper.setProps({ rearrangePanelsAvailable: true });
        return wrapper.vm.$nextTick();
      });

      it('displays rearrange button', () => {
        expect(findRearrangeButton().exists()).toBe(true);
      });

      describe('when rearrange button is clicked', () => {
        const findFirstDraggableRemoveButton = () =>
          findDraggablePanels()
            .at(0)
            .find('.js-draggable-remove');

        beforeEach(() => {
          findRearrangeButton().vm.$emit('click');
          return wrapper.vm.$nextTick();
        });

        it('it enables draggables', () => {
          expect(findRearrangeButton().attributes('pressed')).toBeTruthy();
          expect(findEnabledDraggables()).toEqual(findDraggables());
        });

        it('metrics can be swapped', () => {
          const firstDraggable = findDraggables().at(0);
          const mockMetrics = [...metricsDashboardViewModel.panelGroups[0].panels];

          const firstTitle = mockMetrics[0].title;
          const secondTitle = mockMetrics[1].title;

          // swap two elements and `input` them
          [mockMetrics[0], mockMetrics[1]] = [mockMetrics[1], mockMetrics[0]];
          firstDraggable.vm.$emit('input', mockMetrics);

          return wrapper.vm.$nextTick(() => {
            const { panels } = wrapper.vm.dashboard.panelGroups[0];

            expect(panels[1].title).toEqual(firstTitle);
            expect(panels[0].title).toEqual(secondTitle);
          });
        });

        it('shows a remove button, which removes a panel', () => {
          expect(findFirstDraggableRemoveButton().isEmpty()).toBe(false);

          expect(findDraggablePanels().length).toEqual(metricsDashboardPanelCount);
          findFirstDraggableRemoveButton().trigger('click');

          return wrapper.vm.$nextTick(() => {
            expect(findDraggablePanels().length).toEqual(metricsDashboardPanelCount - 1);
          });
        });

        it('it disables draggables when clicked again', () => {
          findRearrangeButton().vm.$emit('click');
          return wrapper.vm.$nextTick(() => {
            expect(findRearrangeButton().attributes('pressed')).toBeFalsy();
            expect(findEnabledDraggables().length).toBe(0);
          });
        });
      });
    });
  });

  describe('cluster health', () => {
    beforeEach(() => {
      mock.onGet(propsData.metricsEndpoint).reply(statusCodes.OK, JSON.stringify({}));
      createShallowWrapper({ hasMetrics: true, showHeader: false });

      // all_dashboards is not defined in health dashboards
      wrapper.vm.$store.commit(`monitoringDashboard/${types.SET_ALL_DASHBOARDS}`, undefined);
      return wrapper.vm.$nextTick();
    });

    it('hides dashboard header by default', () => {
      expect(wrapper.find({ ref: 'prometheusGraphsHeader' }).exists()).toEqual(false);
    });

    it('renders correctly', () => {
      expect(wrapper.isVueInstance()).toBe(true);
      expect(wrapper.exists()).toBe(true);
    });
  });

  describe('dashboard edit link', () => {
    const findEditLink = () => wrapper.find('.js-edit-link');

    beforeEach(() => {
      createShallowWrapper({ hasMetrics: true });

      wrapper.vm.$store.commit(
        `monitoringDashboard/${types.SET_ALL_DASHBOARDS}`,
        dashboardGitResponse,
      );
      return wrapper.vm.$nextTick();
    });

    it('is not present for the default dashboard', () => {
      expect(findEditLink().exists()).toBe(false);
    });

    it('is present for a custom dashboard, and links to its edit_path', () => {
      const dashboard = dashboardGitResponse[1]; // non-default dashboard
      const currentDashboard = dashboard.path;

      wrapper.setProps({ currentDashboard });
      return wrapper.vm.$nextTick().then(() => {
        expect(findEditLink().exists()).toBe(true);
        expect(findEditLink().attributes('href')).toBe(dashboard.project_blob_path);
      });
    });
  });

  describe('Dashboard dropdown', () => {
    beforeEach(() => {
      createMountedWrapper({ hasMetrics: true }, { stubs: ['graph-group', 'panel-type'] });

      wrapper.vm.$store.commit(
        `monitoringDashboard/${types.SET_ALL_DASHBOARDS}`,
        dashboardGitResponse,
      );

      return wrapper.vm.$nextTick();
    });

    it('shows the dashboard dropdown', () => {
      const dashboardDropdown = wrapper.find(DashboardsDropdown);

      expect(dashboardDropdown.exists()).toBe(true);
    });
  });

  describe('external dashboard link', () => {
    beforeEach(() => {
      createMountedWrapper(
        {
          hasMetrics: true,
          showPanels: false,
          showTimeWindowDropdown: false,
          externalDashboardUrl: '/mockUrl',
        },
        { stubs: ['graph-group', 'panel-type'] },
      );

      return wrapper.vm.$nextTick();
    });

    it('shows the link', () => {
      const externalDashboardButton = wrapper.find('.js-external-dashboard-link');

      expect(externalDashboardButton.exists()).toBe(true);
      expect(externalDashboardButton.is(GlDeprecatedButton)).toBe(true);
      expect(externalDashboardButton.text()).toContain('View full dashboard');
    });
  });

  describe('Clipboard text in panels', () => {
    const currentDashboard = 'TEST_DASHBOARD';

    const getClipboardTextAt = i =>
      wrapper
        .findAll(PanelType)
        .at(i)
        .props('clipboardText');

    beforeEach(() => {
      createShallowWrapper({ hasMetrics: true, currentDashboard });

      setupStoreWithData(wrapper.vm.$store);

      return wrapper.vm.$nextTick();
    });

    it('contains a link to the dashboard', () => {
      expect(getClipboardTextAt(0)).toContain(`dashboard=${currentDashboard}`);
      expect(getClipboardTextAt(0)).toContain(`group=`);
      expect(getClipboardTextAt(0)).toContain(`title=`);
      expect(getClipboardTextAt(0)).toContain(`y_label=`);
    });

    it('strips the undefined parameter', () => {
      wrapper.setProps({ currentDashboard: undefined });

      return wrapper.vm.$nextTick(() => {
        expect(getClipboardTextAt(0)).not.toContain(`dashboard=`);
        expect(getClipboardTextAt(0)).toContain(`y_label=`);
      });
    });

    it('null parameter is stripped', () => {
      wrapper.setProps({ currentDashboard: null });

      return wrapper.vm.$nextTick(() => {
        expect(getClipboardTextAt(0)).not.toContain(`dashboard=`);
        expect(getClipboardTextAt(0)).toContain(`y_label=`);
      });
    });
  });
});
