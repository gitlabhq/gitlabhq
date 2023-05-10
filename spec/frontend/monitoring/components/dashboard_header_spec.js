import { GlDropdownItem, GlSearchBoxByType, GlLoadingIcon, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { redirectTo } from '~/lib/utils/url_utility';
import ActionsMenu from '~/monitoring/components/dashboard_actions_menu.vue';
import DashboardHeader from '~/monitoring/components/dashboard_header.vue';
import DashboardsDropdown from '~/monitoring/components/dashboards_dropdown.vue';
import RefreshButton from '~/monitoring/components/refresh_button.vue';
import { createStore } from '~/monitoring/stores';
import * as types from '~/monitoring/stores/mutation_types';
import DateTimePicker from '~/vue_shared/components/date_time_picker/date_time_picker.vue';
import { environmentData, dashboardGitResponse, dashboardHeaderProps } from '../mock_data';
import { setupAllDashboards, setupStoreWithDashboard, setupStoreWithData } from '../store_utils';

const mockProjectPath = 'https://path/to/project';

jest.mock('~/lib/utils/url_utility', () => ({
  redirectTo: jest.fn(),
  queryToObject: jest.fn(),
  mergeUrlParams: jest.requireActual('~/lib/utils/url_utility').mergeUrlParams,
}));

describe('Dashboard header', () => {
  let store;
  let wrapper;

  const findDashboardDropdown = () => wrapper.findComponent(DashboardsDropdown);

  const findEnvsDropdown = () => wrapper.findComponent({ ref: 'monitorEnvironmentsDropdown' });
  const findEnvsDropdownItems = () => findEnvsDropdown().findAllComponents(GlDropdownItem);
  const findEnvsDropdownSearch = () => findEnvsDropdown().findComponent(GlSearchBoxByType);
  const findEnvsDropdownSearchMsg = () =>
    wrapper.findComponent({ ref: 'monitorEnvironmentsDropdownMsg' });
  const findEnvsDropdownLoadingIcon = () => findEnvsDropdown().findComponent(GlLoadingIcon);

  const findDateTimePicker = () => wrapper.findComponent(DateTimePicker);
  const findRefreshButton = () => wrapper.findComponent(RefreshButton);

  const findActionsMenu = () => wrapper.findComponent(ActionsMenu);

  const setSearchTerm = (searchTerm) => {
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
      beforeEach(async () => {
        setupStoreWithDashboard(store);
        await nextTick();
      });

      it('there are no environments listed', () => {
        expect(findEnvsDropdownItems()).toHaveLength(0);
      });
    });

    describe('when environments data is loaded', () => {
      const currentDashboard = dashboardGitResponse[0].path;
      const currentEnvironmentName = environmentData[0].name;

      beforeEach(async () => {
        setupStoreWithData(store);
        store.state.monitoringDashboard.projectPath = mockProjectPath;
        store.state.monitoringDashboard.currentDashboard = currentDashboard;
        store.state.monitoringDashboard.currentEnvironmentName = currentEnvironmentName;

        await nextTick();
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

      it('environments dropdown items can be checked', () => {
        const items = findEnvsDropdownItems();
        const checkItems = findEnvsDropdownItems().filter((item) => item.props('isCheckItem'));

        expect(items).toHaveLength(checkItems.length);
      });

      it('checks the currently selected environment', () => {
        const selectedItems = findEnvsDropdownItems().filter((item) => item.props('isChecked'));

        expect(selectedItems).toHaveLength(1);
        expect(selectedItems.at(0).text()).toBe(currentEnvironmentName);
      });

      it('filters rendered dropdown items', async () => {
        const searchTerm = 'production';
        const resultEnvs = environmentData.filter(({ name }) => name.indexOf(searchTerm) !== -1);
        setSearchTerm(searchTerm);

        await nextTick();
        expect(findEnvsDropdownItems()).toHaveLength(resultEnvs.length);
      });

      it('does not filter dropdown items if search term is empty string', async () => {
        const searchTerm = '';
        setSearchTerm(searchTerm);

        await nextTick();
        expect(findEnvsDropdownItems()).toHaveLength(environmentData.length);
      });

      it("shows error message if search term doesn't match", async () => {
        const searchTerm = 'does-not-exist';
        setSearchTerm(searchTerm);

        await nextTick();
        expect(findEnvsDropdownSearchMsg().isVisible()).toBe(true);
      });

      it('shows loading element when environments fetch is still loading', async () => {
        store.commit(`monitoringDashboard/${types.REQUEST_ENVIRONMENTS_DATA}`);

        await nextTick();
        expect(findEnvsDropdownLoadingIcon().exists()).toBe(true);
        await store.commit(
          `monitoringDashboard/${types.RECEIVE_ENVIRONMENTS_DATA_SUCCESS}`,
          environmentData,
        );
        expect(findEnvsDropdownLoadingIcon().exists()).toBe(false);
      });
    });
  });

  describe('date time picker', () => {
    beforeEach(() => {
      createShallowWrapper();
    });

    it('is rendered', () => {
      expect(findDateTimePicker().exists()).toBe(true);
    });

    describe('timezone setting', () => {
      const setupWithTimezone = (value) => {
        store = createStore({ dashboardTimezone: value });
        createShallowWrapper();
      };

      describe('local timezone is enabled by default', () => {
        it('shows the data time picker in local timezone', () => {
          expect(findDateTimePicker().props('utc')).toBe(false);
        });
      });

      describe('when LOCAL timezone is enabled', () => {
        beforeEach(() => {
          setupWithTimezone('LOCAL');
        });

        it('shows the data time picker in local timezone', () => {
          expect(findDateTimePicker().props('utc')).toBe(false);
        });
      });

      describe('when UTC timezone is enabled', () => {
        beforeEach(() => {
          setupWithTimezone('UTC');
        });

        it('shows the data time picker in UTC format', () => {
          expect(findDateTimePicker().props('utc')).toBe(true);
        });
      });
    });
  });

  describe('refresh button', () => {
    beforeEach(() => {
      createShallowWrapper();
    });

    it('is rendered', () => {
      expect(findRefreshButton().exists()).toBe(true);
    });
  });

  describe('external dashboard link', () => {
    beforeEach(async () => {
      store.state.monitoringDashboard.externalDashboardUrl = '/mockUrl';
      createShallowWrapper();

      await nextTick();
    });

    it('shows the link', () => {
      const externalDashboardButton = wrapper.find('.js-external-dashboard-link');

      expect(externalDashboardButton.exists()).toBe(true);
      expect(externalDashboardButton.is(GlButton)).toBe(true);
      expect(externalDashboardButton.text()).toContain('View full dashboard');
    });
  });

  describe('actions menu', () => {
    const ootbDashboards = [dashboardGitResponse[0].path];
    const customDashboards = [dashboardGitResponse[1].path];

    it('is rendered', () => {
      createShallowWrapper();

      expect(findActionsMenu().exists()).toBe(true);
    });

    describe('adding metrics prop', () => {
      it.each(ootbDashboards)(
        'gets passed true if current dashboard is OOTB',
        async (dashboardPath) => {
          createShallowWrapper({ customMetricsAvailable: true });

          store.state.monitoringDashboard.emptyState = false;
          setupAllDashboards(store, dashboardPath);

          await nextTick();
          expect(findActionsMenu().props('addingMetricsAvailable')).toBe(true);
        },
      );

      it.each(customDashboards)(
        'gets passed false if current dashboard is custom',
        async (dashboardPath) => {
          createShallowWrapper({ customMetricsAvailable: true });

          store.state.monitoringDashboard.emptyState = false;
          setupAllDashboards(store, dashboardPath);

          await nextTick();
          expect(findActionsMenu().props('addingMetricsAvailable')).toBe(false);
        },
      );

      it('gets passed false if empty state is shown', async () => {
        createShallowWrapper({ customMetricsAvailable: true });

        store.state.monitoringDashboard.emptyState = true;
        setupAllDashboards(store, ootbDashboards[0]);

        await nextTick();
        expect(findActionsMenu().props('addingMetricsAvailable')).toBe(false);
      });

      it('gets passed false if custom metrics are not available', async () => {
        createShallowWrapper({ customMetricsAvailable: false });

        store.state.monitoringDashboard.emptyState = false;
        setupAllDashboards(store, ootbDashboards[0]);

        await nextTick();
        expect(findActionsMenu().props('addingMetricsAvailable')).toBe(false);
      });
    });

    it('custom metrics path gets passed', async () => {
      const path = 'https://path/to/customMetrics';

      createShallowWrapper({ customMetricsPath: path });

      await nextTick();
      expect(findActionsMenu().props('customMetricsPath')).toBe(path);
    });

    it('validate query path gets passed', async () => {
      const path = 'https://path/to/validateQuery';

      createShallowWrapper({ validateQueryPath: path });

      await nextTick();
      expect(findActionsMenu().props('validateQueryPath')).toBe(path);
    });

    it('default branch gets passed', async () => {
      const branch = 'branchName';

      createShallowWrapper({ defaultBranch: branch });

      await nextTick();
      expect(findActionsMenu().props('defaultBranch')).toBe(branch);
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

    it('is rendered when the user can access the project settings and path to settings is available', async () => {
      store.state.monitoringDashboard.canAccessOperationsSettings = true;
      store.state.monitoringDashboard.operationsSettingsPath = url;

      await nextTick();
      expect(findSettingsButton().exists()).toBe(true);
    });

    it('is not rendered when the user can not access the project settings', async () => {
      store.state.monitoringDashboard.canAccessOperationsSettings = false;
      store.state.monitoringDashboard.operationsSettingsPath = url;

      await nextTick();
      expect(findSettingsButton().exists()).toBe(false);
    });

    it('is not rendered when the path to settings is unavailable', async () => {
      store.state.monitoringDashboard.canAccessOperationsSettings = false;
      store.state.monitoringDashboard.operationsSettingsPath = '';

      await nextTick();
      expect(findSettingsButton().exists()).toBe(false);
    });

    it('leads to the project settings page', async () => {
      store.state.monitoringDashboard.canAccessOperationsSettings = true;
      store.state.monitoringDashboard.operationsSettingsPath = url;

      await nextTick();
      expect(findSettingsButton().attributes('href')).toBe(url);
    });
  });
});
