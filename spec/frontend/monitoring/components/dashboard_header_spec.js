import { shallowMount } from '@vue/test-utils';
import { createStore } from '~/monitoring/stores';
import * as types from '~/monitoring/stores/mutation_types';
import { GlDeprecatedDropdownItem, GlSearchBoxByType, GlLoadingIcon } from '@gitlab/ui';
import DashboardHeader from '~/monitoring/components/dashboard_header.vue';
import DashboardsDropdown from '~/monitoring/components/dashboards_dropdown.vue';
import DuplicateDashboardModal from '~/monitoring/components/duplicate_dashboard_modal.vue';
import CreateDashboardModal from '~/monitoring/components/create_dashboard_modal.vue';
import { setupAllDashboards, setupStoreWithDashboard, setupStoreWithData } from '../store_utils';
import {
  environmentData,
  dashboardGitResponse,
  selfMonitoringDashboardGitResponse,
  dashboardHeaderProps,
} from '../mock_data';
import { redirectTo } from '~/lib/utils/url_utility';

const mockProjectPath = 'https://path/to/project';

jest.mock('~/lib/utils/url_utility', () => ({
  redirectTo: jest.fn(),
  queryToObject: jest.fn(),
  mergeUrlParams: jest.requireActual('~/lib/utils/url_utility').mergeUrlParams,
}));

describe('Dashboard header', () => {
  let store;
  let wrapper;

  const findDashboardDropdown = () => wrapper.find(DashboardsDropdown);

  const findEnvsDropdown = () => wrapper.find({ ref: 'monitorEnvironmentsDropdown' });
  const findEnvsDropdownItems = () => findEnvsDropdown().findAll(GlDeprecatedDropdownItem);
  const findEnvsDropdownSearch = () => findEnvsDropdown().find(GlSearchBoxByType);
  const findEnvsDropdownSearchMsg = () => wrapper.find({ ref: 'monitorEnvironmentsDropdownMsg' });
  const findEnvsDropdownLoadingIcon = () => findEnvsDropdown().find(GlLoadingIcon);

  const findActionsMenu = () => wrapper.find('[data-testid="actions-menu"]');
  const findCreateDashboardMenuItem = () =>
    findActionsMenu().find('[data-testid="action-create-dashboard"]');
  const findCreateDashboardDuplicateItem = () =>
    findActionsMenu().find('[data-testid="action-duplicate-dashboard"]');
  const findDuplicateDashboardModal = () => wrapper.find(DuplicateDashboardModal);
  const findCreateDashboardModal = () => wrapper.find('[data-testid="create-dashboard-modal"]');

  const setSearchTerm = searchTerm => {
    store.commit(`monitoringDashboard/${types.SET_ENVIRONMENTS_FILTER}`, searchTerm);
  };

  const createShallowWrapper = (props = {}, options = {}) => {
    wrapper = shallowMount(DashboardHeader, {
      propsData: { ...dashboardHeaderProps, ...props },
      store,
      ...options,
    });
  };

  beforeEach(() => {
    store = createStore();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('dashboards dropdown', () => {
    beforeEach(() => {
      store.commit(`monitoringDashboard/${types.SET_INITIAL_STATE}`, {
        projectPath: mockProjectPath,
      });

      createShallowWrapper();
    });

    it('shows the dashboard dropdown', () => {
      expect(findDashboardDropdown().exists()).toBe(true);
    });

    it('when an out of the box dashboard is selected, encodes dashboard path', () => {
      findDashboardDropdown().vm.$emit('selectDashboard', {
        path: '.gitlab/dashboards/dashboard&copy.yml',
        out_of_the_box_dashboard: true,
        display_name: 'A display name',
      });

      expect(redirectTo).toHaveBeenCalledWith(
        `${mockProjectPath}/-/metrics/.gitlab%2Fdashboards%2Fdashboard%26copy.yml`,
      );
    });

    it('when a custom dashboard is selected, encodes dashboard display name', () => {
      findDashboardDropdown().vm.$emit('selectDashboard', {
        path: '.gitlab/dashboards/file&path.yml',
        display_name: 'dashboard&copy.yml',
      });

      expect(redirectTo).toHaveBeenCalledWith(`${mockProjectPath}/-/metrics/dashboard%26copy.yml`);
    });
  });

  describe('environments dropdown', () => {
    beforeEach(() => {
      createShallowWrapper();
    });

    it('shows the environments dropdown', () => {
      expect(findEnvsDropdown().exists()).toBe(true);
    });

    it('renders a search input', () => {
      expect(findEnvsDropdownSearch().exists()).toBe(true);
    });

    describe('when environments data is not loaded', () => {
      beforeEach(() => {
        setupStoreWithDashboard(store);
        return wrapper.vm.$nextTick();
      });

      it('there are no environments listed', () => {
        expect(findEnvsDropdownItems().length).toBe(0);
      });
    });

    describe('when environments data is loaded', () => {
      const currentDashboard = dashboardGitResponse[0].path;
      const currentEnvironmentName = environmentData[0].name;

      beforeEach(() => {
        setupStoreWithData(store);
        store.state.monitoringDashboard.projectPath = mockProjectPath;
        store.state.monitoringDashboard.currentDashboard = currentDashboard;
        store.state.monitoringDashboard.currentEnvironmentName = currentEnvironmentName;

        return wrapper.vm.$nextTick();
      });

      it('renders dropdown items with the environment name', () => {
        const path = `${mockProjectPath}/-/metrics/${encodeURIComponent(currentDashboard)}`;

        findEnvsDropdownItems().wrappers.forEach((itemWrapper, index) => {
          const { name, id } = environmentData[index];
          const idParam = encodeURIComponent(id);

          expect(itemWrapper.text()).toBe(name);
          expect(itemWrapper.attributes('href')).toBe(`${path}?environment=${idParam}`);
        });
      });

      it('renders the environments dropdown with an active element', () => {
        const selectedItems = findEnvsDropdownItems().filter(
          item => item.attributes('active') === 'true',
        );

        expect(selectedItems.length).toBe(1);
        expect(selectedItems.at(0).text()).toBe(currentEnvironmentName);
      });

      it('filters rendered dropdown items', () => {
        const searchTerm = 'production';
        const resultEnvs = environmentData.filter(({ name }) => name.indexOf(searchTerm) !== -1);
        setSearchTerm(searchTerm);

        return wrapper.vm.$nextTick().then(() => {
          expect(findEnvsDropdownItems().length).toBe(resultEnvs.length);
        });
      });

      it('does not filter dropdown items if search term is empty string', () => {
        const searchTerm = '';
        setSearchTerm(searchTerm);

        return wrapper.vm.$nextTick(() => {
          expect(findEnvsDropdownItems().length).toBe(environmentData.length);
        });
      });

      it("shows error message if search term doesn't match", () => {
        const searchTerm = 'does-not-exist';
        setSearchTerm(searchTerm);

        return wrapper.vm.$nextTick(() => {
          expect(findEnvsDropdownSearchMsg().isVisible()).toBe(true);
        });
      });

      it('shows loading element when environments fetch is still loading', () => {
        store.commit(`monitoringDashboard/${types.REQUEST_ENVIRONMENTS_DATA}`);

        return wrapper.vm
          .$nextTick()
          .then(() => {
            expect(findEnvsDropdownLoadingIcon().exists()).toBe(true);
          })
          .then(() => {
            store.commit(
              `monitoringDashboard/${types.RECEIVE_ENVIRONMENTS_DATA_SUCCESS}`,
              environmentData,
            );
          })
          .then(() => {
            expect(findEnvsDropdownLoadingIcon().exists()).toBe(false);
          });
      });
    });
  });

  describe('when a dashboard has been duplicated in the duplicate dashboard modal', () => {
    beforeEach(() => {
      store.state.monitoringDashboard.projectPath = 'root/sandbox';

      setupAllDashboards(store, dashboardGitResponse[0].path);
    });

    it('redirects to the newly created dashboard', () => {
      delete window.location;
      window.location = new URL('https://localhost');

      const newDashboard = dashboardGitResponse[1];

      createShallowWrapper();

      const newDashboardUrl = 'root/sandbox/-/metrics/dashboard.yml';
      findDuplicateDashboardModal().vm.$emit('dashboardDuplicated', newDashboard);

      return wrapper.vm.$nextTick().then(() => {
        expect(redirectTo).toHaveBeenCalled();
        expect(redirectTo).toHaveBeenCalledWith(newDashboardUrl);
      });
    });
  });

  describe('actions menu', () => {
    beforeEach(() => {
      store.state.monitoringDashboard.projectPath = '';
      createShallowWrapper();
    });

    it('is rendered if projectPath is set in store', () => {
      store.state.monitoringDashboard.projectPath = mockProjectPath;

      return wrapper.vm.$nextTick().then(() => {
        expect(findActionsMenu().exists()).toBe(true);
      });
    });

    it('is not rendered if projectPath is not set in store', () => {
      expect(findActionsMenu().exists()).toBe(false);
    });

    it('contains the create dashboard modal', () => {
      store.state.monitoringDashboard.projectPath = mockProjectPath;

      return wrapper.vm.$nextTick().then(() => {
        expect(findActionsMenu().contains(CreateDashboardModal)).toBe(true);
      });
    });

    const duplicableCases = [
      null, // When no path is specified, it uses the default dashboard path.
      dashboardGitResponse[0].path,
      dashboardGitResponse[2].path,
      selfMonitoringDashboardGitResponse[0].path,
    ];

    describe.each(duplicableCases)(
      'when the selected dashboard can be duplicated',
      dashboardPath => {
        it('contains menu items for "Create New", "Duplicate Dashboard" and a modal for duplicating dashboards', () => {
          store.state.monitoringDashboard.projectPath = mockProjectPath;
          setupAllDashboards(store, dashboardPath);

          return wrapper.vm.$nextTick().then(() => {
            expect(findCreateDashboardMenuItem().exists()).toBe(true);
            expect(findCreateDashboardDuplicateItem().exists()).toBe(true);
            expect(findDuplicateDashboardModal().exists()).toBe(true);
          });
        });
      },
    );

    const nonDuplicableCases = [
      dashboardGitResponse[1].path,
      selfMonitoringDashboardGitResponse[1].path,
    ];

    describe.each(nonDuplicableCases)(
      'when the selected dashboard cannot be duplicated',
      dashboardPath => {
        it('contains a "Create New" menu item, but no "Duplicate Dashboard" menu item and modal', () => {
          store.state.monitoringDashboard.projectPath = mockProjectPath;
          setupAllDashboards(store, dashboardPath);

          return wrapper.vm.$nextTick().then(() => {
            expect(findCreateDashboardMenuItem().exists()).toBe(true);
            expect(findCreateDashboardDuplicateItem().exists()).toBe(false);
            expect(findDuplicateDashboardModal().exists()).toBe(false);
          });
        });
      },
    );
  });

  describe('actions menu modals', () => {
    beforeEach(() => {
      store.state.monitoringDashboard.projectPath = mockProjectPath;
      setupAllDashboards(store);

      createShallowWrapper();
    });

    it('Clicking on "Create New" opens up a modal', () => {
      const modalId = 'createDashboard';
      const modalTrigger = findCreateDashboardMenuItem();
      const rootEmit = jest.spyOn(wrapper.vm.$root, '$emit');

      modalTrigger.trigger('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(rootEmit.mock.calls[0]).toContainEqual(modalId);
      });
    });

    it('"Create new dashboard" modal contains correct buttons', () => {
      expect(findCreateDashboardModal().props('projectPath')).toBe(mockProjectPath);
    });

    it('"Duplicate Dashboard" opens up a modal', () => {
      const modalId = 'duplicateDashboard';
      const modalTrigger = findCreateDashboardDuplicateItem();
      const rootEmit = jest.spyOn(wrapper.vm.$root, '$emit');

      modalTrigger.trigger('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(rootEmit.mock.calls[0]).toContainEqual(modalId);
      });
    });
  });

  describe('metrics settings button', () => {
    const findSettingsButton = () => wrapper.find('[data-testid="metrics-settings-button"]');
    const url = 'https://path/to/project/settings';

    beforeEach(() => {
      createShallowWrapper();

      store.state.monitoringDashboard.canAccessOperationsSettings = false;
      store.state.monitoringDashboard.operationsSettingsPath = '';
    });

    it('is rendered when the user can access the project settings and path to settings is available', () => {
      store.state.monitoringDashboard.canAccessOperationsSettings = true;
      store.state.monitoringDashboard.operationsSettingsPath = url;

      return wrapper.vm.$nextTick(() => {
        expect(findSettingsButton().exists()).toBe(true);
      });
    });

    it('is not rendered when the user can not access the project settings', () => {
      store.state.monitoringDashboard.canAccessOperationsSettings = false;
      store.state.monitoringDashboard.operationsSettingsPath = url;

      return wrapper.vm.$nextTick(() => {
        expect(findSettingsButton().exists()).toBe(false);
      });
    });

    it('is not rendered when the path to settings is unavailable', () => {
      store.state.monitoringDashboard.canAccessOperationsSettings = false;
      store.state.monitoringDashboard.operationsSettingsPath = '';

      return wrapper.vm.$nextTick(() => {
        expect(findSettingsButton().exists()).toBe(false);
      });
    });

    it('leads to the project settings page', () => {
      store.state.monitoringDashboard.canAccessOperationsSettings = true;
      store.state.monitoringDashboard.operationsSettingsPath = url;

      return wrapper.vm.$nextTick(() => {
        expect(findSettingsButton().attributes('href')).toBe(url);
      });
    });
  });

  describe('Add metric button', () => {
    const findAddMetricButton = () => wrapper.find('[data-qa-selector="add_metric_button"]');

    it('is not rendered when custom metrics are not available', () => {
      store.state.monitoringDashboard.emptyState = false;

      createShallowWrapper({
        customMetricsAvailable: false,
      });

      setupAllDashboards(store, dashboardGitResponse[0].path);

      return wrapper.vm.$nextTick(() => {
        expect(findAddMetricButton().exists()).toBe(false);
      });
    });

    it('is not rendered when displaying empty state', () => {
      store.state.monitoringDashboard.emptyState = true;

      createShallowWrapper({
        customMetricsAvailable: true,
      });

      setupAllDashboards(store, dashboardGitResponse[0].path);

      return wrapper.vm.$nextTick(() => {
        expect(findAddMetricButton().exists()).toBe(false);
      });
    });

    describe('system dashboards', () => {
      const systemDashboards = [
        dashboardGitResponse[0].path,
        selfMonitoringDashboardGitResponse[0].path,
      ];
      const nonSystemDashboards = [
        dashboardGitResponse[1].path,
        dashboardGitResponse[2].path,
        selfMonitoringDashboardGitResponse[1].path,
      ];

      beforeEach(() => {
        store.state.monitoringDashboard.emptyState = false;

        createShallowWrapper({
          customMetricsAvailable: true,
        });
      });

      test.each(systemDashboards)('is rendered for system dashboards', dashboardPath => {
        setupAllDashboards(store, dashboardPath);

        return wrapper.vm.$nextTick(() => {
          expect(findAddMetricButton().exists()).toBe(true);
        });
      });

      test.each(nonSystemDashboards)('is not rendered for non-system dashboards', dashboardPath => {
        setupAllDashboards(store, dashboardPath);

        return wrapper.vm.$nextTick(() => {
          expect(findAddMetricButton().exists()).toBe(false);
        });
      });
    });
  });
});
