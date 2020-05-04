import { shallowMount, mount } from '@vue/test-utils';
import Tracking from '~/tracking';
import { ESC_KEY, ESC_KEY_IE11 } from '~/lib/utils/keys';
import { GlModal, GlDropdownItem, GlDeprecatedButton } from '@gitlab/ui';
import VueDraggable from 'vuedraggable';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import statusCodes from '~/lib/utils/http_status';
import { metricStates } from '~/monitoring/constants';
import Dashboard from '~/monitoring/components/dashboard.vue';

import DateTimePicker from '~/vue_shared/components/date_time_picker/date_time_picker.vue';
import CustomMetricsFormFields from '~/custom_metrics/components/custom_metrics_form_fields.vue';
import DashboardsDropdown from '~/monitoring/components/dashboards_dropdown.vue';
import EmptyState from '~/monitoring/components/empty_state.vue';
import GroupEmptyState from '~/monitoring/components/group_empty_state.vue';
import DashboardPanel from '~/monitoring/components/dashboard_panel.vue';
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
      store,
      ...options,
    });
  };

  const createMountedWrapper = (props = {}, options = {}) => {
    wrapper = mount(Dashboard, {
      propsData: { ...propsData, ...props },
      store,
      stubs: ['graph-group', 'dashboard-panel'],
      ...options,
    });
  };

  beforeEach(() => {
    store = createStore();
    mock = new MockAdapter(axios);
    jest.spyOn(store, 'dispatch').mockResolvedValue();
  });

  afterEach(() => {
    mock.restore();
    if (store.dispatch.mockReset) {
      store.dispatch.mockReset();
    }
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
      createShallowWrapper({ hasMetrics: true });

      return wrapper.vm.$nextTick().then(() => {
        expect(store.dispatch).toHaveBeenCalledWith(
          'monitoringDashboard/setTimeRange',
          expect.any(Object),
        );

        expect(store.dispatch).toHaveBeenCalledWith('monitoringDashboard/fetchData', undefined);
      });
    });

    it('shows up a loading state', () => {
      store.state.monitoringDashboard.emptyState = 'loading';

      createShallowWrapper({ hasMetrics: true });

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.find(EmptyState).exists()).toBe(true);
        expect(wrapper.find(EmptyState).props('selectedState')).toBe('loading');
      });
    });

    it('hides the group panels when showPanels is false', () => {
      createMountedWrapper({ hasMetrics: true, showPanels: false });

      setupStoreWithData(wrapper.vm.$store);

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.vm.showEmptyState).toEqual(false);
        expect(wrapper.findAll('.prometheus-panel')).toHaveLength(0);
      });
    });

    it('fetches the metrics data with proper time window', () => {
      jest.spyOn(store, 'dispatch');

      createMountedWrapper({ hasMetrics: true });

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
      createMountedWrapper({ hasMetrics: true });

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
    createMountedWrapper({ hasMetrics: true });

    setupStoreWithDashboard(wrapper.vm.$store);

    return wrapper.vm.$nextTick().then(() => {
      expect(findAllEnvironmentsDropdownItems()).toHaveLength(0);
    });
  });

  it('renders the datetimepicker dropdown', () => {
    createMountedWrapper({ hasMetrics: true });

    setupStoreWithData(wrapper.vm.$store);

    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.find(DateTimePicker).exists()).toBe(true);
    });
  });

  it('renders the refresh dashboard button', () => {
    createMountedWrapper({ hasMetrics: true });

    setupStoreWithData(wrapper.vm.$store);

    return wrapper.vm.$nextTick().then(() => {
      const refreshBtn = wrapper.findAll({ ref: 'refreshDashboardBtn' });

      expect(refreshBtn).toHaveLength(1);
      expect(refreshBtn.is(GlDeprecatedButton)).toBe(true);
    });
  });

  describe('single panel expands to "full screen" mode', () => {
    const findExpandedPanel = () => wrapper.find({ ref: 'expandedPanel' });

    describe('when the panel is not expanded', () => {
      beforeEach(() => {
        createShallowWrapper({ hasMetrics: true });
        setupStoreWithData(wrapper.vm.$store);
        return wrapper.vm.$nextTick();
      });

      it('expanded panel is not visible', () => {
        expect(findExpandedPanel().isVisible()).toBe(false);
      });

      it('can set a panel as expanded', () => {
        const panel = wrapper.findAll(DashboardPanel).at(1);

        jest.spyOn(store, 'dispatch');

        panel.vm.$emit('expand');

        const groupData = metricsDashboardViewModel.panelGroups[0];

        expect(store.dispatch).toHaveBeenCalledWith('monitoringDashboard/setExpandedPanel', {
          group: groupData.group,
          panel: expect.objectContaining({
            id: groupData.panels[0].id,
          }),
        });
      });
    });

    describe('when the panel is expanded', () => {
      let group;
      let panel;

      const mockKeyup = key => window.dispatchEvent(new KeyboardEvent('keyup', { key }));

      const MockPanel = {
        template: `<div><slot name="topLeft"/></div>`,
      };

      beforeEach(() => {
        createShallowWrapper({ hasMetrics: true }, { stubs: { DashboardPanel: MockPanel } });
        setupStoreWithData(wrapper.vm.$store);

        const { panelGroups } = wrapper.vm.$store.state.monitoringDashboard.dashboard;

        group = panelGroups[0].group;
        [panel] = panelGroups[0].panels;

        wrapper.vm.$store.commit(`monitoringDashboard/${types.SET_EXPANDED_PANEL}`, {
          group,
          panel,
        });

        jest.spyOn(store, 'dispatch');

        return wrapper.vm.$nextTick();
      });

      it('displays a single panel and others are hidden', () => {
        const panels = wrapper.findAll(MockPanel);
        const visiblePanels = panels.filter(w => w.isVisible());

        expect(findExpandedPanel().isVisible()).toBe(true);
        // v-show for hiding panels is more performant than v-if
        // check for panels to be hidden.
        expect(panels.length).toBe(metricsDashboardPanelCount + 1);
        expect(visiblePanels.length).toBe(1);
      });

      it('sets a link to the expanded panel', () => {
        const searchQuery =
          '?group=System%20metrics%20(Kubernetes)&title=Memory%20Usage%20(Total)&y_label=Total%20Memory%20Used%20(GB)';

        expect(findExpandedPanel().attributes('clipboard-text')).toEqual(
          expect.stringContaining(searchQuery),
        );
      });

      it('restores full dashboard by clicking `back`', () => {
        wrapper.find({ ref: 'goBackBtn' }).vm.$emit('click');

        expect(store.dispatch).toHaveBeenCalledWith(
          'monitoringDashboard/clearExpandedPanel',
          undefined,
        );
      });

      it('restores dashboard from full screen by typing the Escape key', () => {
        mockKeyup(ESC_KEY);
        expect(store.dispatch).toHaveBeenCalledWith(
          `monitoringDashboard/clearExpandedPanel`,
          undefined,
        );
      });

      it('restores dashboard from full screen by typing the Escape key on IE11', () => {
        mockKeyup(ESC_KEY_IE11);

        expect(store.dispatch).toHaveBeenCalledWith(
          `monitoringDashboard/clearExpandedPanel`,
          undefined,
        );
      });
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
      createMountedWrapper({ hasMetrics: true }, { attachToDocument: true });

      setupStoreWithData(wrapper.vm.$store);

      return wrapper.vm.$nextTick();
    });

    afterEach(() => {
      wrapper.destroy();
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
      // call original dispatch
      store.dispatch.mockRestore();

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
      createMountedWrapper({ hasMetrics: true });

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
      createMountedWrapper({
        hasMetrics: true,
        showPanels: false,
        showTimeWindowDropdown: false,
        externalDashboardUrl: '/mockUrl',
      });

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
    const panelIndex = 1; // skip expanded panel

    const getClipboardTextFirstPanel = () =>
      wrapper
        .findAll(DashboardPanel)
        .at(panelIndex)
        .props('clipboardText');

    beforeEach(() => {
      createShallowWrapper({ hasMetrics: true, currentDashboard });

      setupStoreWithData(wrapper.vm.$store);

      return wrapper.vm.$nextTick();
    });

    it('contains a link to the dashboard', () => {
      expect(getClipboardTextFirstPanel()).toContain(`dashboard=${currentDashboard}`);
      expect(getClipboardTextFirstPanel()).toContain(`group=`);
      expect(getClipboardTextFirstPanel()).toContain(`title=`);
      expect(getClipboardTextFirstPanel()).toContain(`y_label=`);
    });

    it('strips the undefined parameter', () => {
      wrapper.setProps({ currentDashboard: undefined });

      return wrapper.vm.$nextTick(() => {
        expect(getClipboardTextFirstPanel()).not.toContain(`dashboard=`);
        expect(getClipboardTextFirstPanel()).toContain(`y_label=`);
      });
    });

    it('null parameter is stripped', () => {
      wrapper.setProps({ currentDashboard: null });

      return wrapper.vm.$nextTick(() => {
        expect(getClipboardTextFirstPanel()).not.toContain(`dashboard=`);
        expect(getClipboardTextFirstPanel()).toContain(`y_label=`);
      });
    });
  });

  describe('add custom metrics', () => {
    const findAddMetricButton = () => wrapper.vm.$refs.addMetricBtn;
    describe('when not available', () => {
      beforeEach(() => {
        createShallowWrapper({
          hasMetrics: true,
          customMetricsPath: '/endpoint',
        });
      });
      it('does not render add button on the dashboard', () => {
        expect(findAddMetricButton()).toBeUndefined();
      });
    });

    describe('when available', () => {
      let origPage;
      beforeEach(done => {
        jest.spyOn(Tracking, 'event').mockReturnValue();
        createShallowWrapper({
          hasMetrics: true,
          customMetricsPath: '/endpoint',
          customMetricsAvailable: true,
        });
        setupStoreWithData(wrapper.vm.$store);

        origPage = document.body.dataset.page;
        document.body.dataset.page = 'projects:environments:metrics';

        wrapper.vm.$nextTick(done);
      });
      afterEach(() => {
        document.body.dataset.page = origPage;
      });

      it('renders add button on the dashboard', () => {
        expect(findAddMetricButton()).toBeDefined();
      });

      it('uses modal for custom metrics form', () => {
        expect(wrapper.find(GlModal).exists()).toBe(true);
        expect(wrapper.find(GlModal).attributes().modalid).toBe('add-metric');
      });
      it('adding new metric is tracked', done => {
        const submitButton = wrapper.vm.$refs.submitCustomMetricsFormBtn;
        wrapper.setData({
          formIsValid: true,
        });
        wrapper.vm.$nextTick(() => {
          submitButton.$el.click();
          wrapper.vm.$nextTick(() => {
            expect(Tracking.event).toHaveBeenCalledWith(
              document.body.dataset.page,
              'click_button',
              {
                label: 'add_new_metric',
                property: 'modal',
                value: undefined,
              },
            );
            done();
          });
        });
      });

      it('renders custom metrics form fields', () => {
        expect(wrapper.find(CustomMetricsFormFields).exists()).toBe(true);
      });
    });
  });
});
