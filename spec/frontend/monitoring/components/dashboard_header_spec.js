import { shallowMount } from '@vue/test-utils';
import { createStore } from '~/monitoring/stores';
import * as types from '~/monitoring/stores/mutation_types';
import { GlDropdownItem, GlSearchBoxByType, GlLoadingIcon } from '@gitlab/ui';
import DashboardHeader from '~/monitoring/components/dashboard_header.vue';
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

  const findEnvsDropdown = () => wrapper.find({ ref: 'monitorEnvironmentsDropdown' });
  const findEnvsDropdownItems = () => findEnvsDropdown().findAll(GlDropdownItem);
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

      beforeEach(() => {
        setupStoreWithData(store);
        store.state.monitoringDashboard.projectPath = mockProjectPath;
        store.state.monitoringDashboard.currentDashboard = currentDashboard;

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

      // Note: This test is not working, .active does not show the active environment
      // https://gitlab.com/gitlab-org/gitlab/-/issues/230615
      // eslint-disable-next-line jest/no-disabled-tests
      it.skip('renders the environments dropdown with a single active element', () => {
        const activeItem = findEnvsDropdownItems().wrappers.filter(itemWrapper =>
          itemWrapper.find('.active').exists(),
        );

        expect(activeItem.length).toBe(1);
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
    });
    /**
     * The duplicate dashboard modal gets called both by a menu item from the
     * dashboards dropdown and by an item from the actions menu.
     *
     * This spec is context agnostic, so it addresses all cases where the
     * duplicate dashboard modal gets called.
     */
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

    it('contains a modal', () => {
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
        it('contains a "Create New" menu item and a "Duplicate Dashboard" menu item', () => {
          store.state.monitoringDashboard.projectPath = mockProjectPath;
          setupAllDashboards(store, dashboardPath);

          return wrapper.vm.$nextTick().then(() => {
            expect(findCreateDashboardMenuItem().exists()).toBe(true);
            expect(findCreateDashboardDuplicateItem().exists()).toBe(true);
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
        it('contains a "Create New" menu item and no "Duplicate Dashboard" menu item', () => {
          store.state.monitoringDashboard.projectPath = mockProjectPath;
          setupAllDashboards(store, dashboardPath);

          return wrapper.vm.$nextTick().then(() => {
            expect(findCreateDashboardMenuItem().exists()).toBe(true);
            expect(findCreateDashboardDuplicateItem().exists()).toBe(false);
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
});
