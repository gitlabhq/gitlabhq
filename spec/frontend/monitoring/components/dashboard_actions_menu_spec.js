import { GlDropdownItem, GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import CustomMetricsFormFields from '~/custom_metrics/components/custom_metrics_form_fields.vue';
import { redirectTo } from '~/lib/utils/url_utility';
import ActionsMenu from '~/monitoring/components/dashboard_actions_menu.vue';
import { DASHBOARD_PAGE, PANEL_NEW_PAGE } from '~/monitoring/router/constants';
import { createStore } from '~/monitoring/stores';
import * as types from '~/monitoring/stores/mutation_types';
import Tracking from '~/tracking';
import { dashboardActionsMenuProps, dashboardGitResponse } from '../mock_data';
import { setupAllDashboards, setupStoreWithData } from '../store_utils';

jest.mock('~/lib/utils/url_utility', () => ({
  redirectTo: jest.fn(),
  queryToObject: jest.fn(),
}));

describe('Actions menu', () => {
  const ootbDashboards = [dashboardGitResponse[0], dashboardGitResponse[2]];
  const customDashboard = dashboardGitResponse[1];

  let store;
  let wrapper;

  const findAddMetricItem = () => wrapper.find('[data-testid="add-metric-item"]');
  const findAddPanelItemEnabled = () => wrapper.find('[data-testid="add-panel-item-enabled"]');
  const findAddPanelItemDisabled = () => wrapper.find('[data-testid="add-panel-item-disabled"]');
  const findAddMetricModal = () => wrapper.find('[data-testid="add-metric-modal"]');
  const findAddMetricModalSubmitButton = () =>
    wrapper.find('[data-testid="add-metric-modal-submit-button"]');
  const findStarDashboardItem = () => wrapper.find('[data-testid="star-dashboard-item"]');
  const findEditDashboardItemEnabled = () =>
    wrapper.find('[data-testid="edit-dashboard-item-enabled"]');
  const findEditDashboardItemDisabled = () =>
    wrapper.find('[data-testid="edit-dashboard-item-disabled"]');
  const findDuplicateDashboardItem = () => wrapper.find('[data-testid="duplicate-dashboard-item"]');
  const findDuplicateDashboardModal = () =>
    wrapper.find('[data-testid="duplicate-dashboard-modal"]');
  const findCreateDashboardItem = () => wrapper.find('[data-testid="create-dashboard-item"]');
  const findCreateDashboardModal = () => wrapper.find('[data-testid="create-dashboard-modal"]');

  const createShallowWrapper = (props = {}, options = {}) => {
    wrapper = shallowMount(ActionsMenu, {
      propsData: { ...dashboardActionsMenuProps, ...props },
      store,
      stubs: {
        GlModal,
      },
      ...options,
    });
  };

  beforeEach(() => {
    store = createStore();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('add metric item', () => {
    it('is rendered when custom metrics are available', () => {
      createShallowWrapper();

      return wrapper.vm.$nextTick(() => {
        expect(findAddMetricItem().exists()).toBe(true);
      });
    });

    it('is not rendered when custom metrics are not available', () => {
      createShallowWrapper({
        addingMetricsAvailable: false,
      });

      return wrapper.vm.$nextTick(() => {
        expect(findAddMetricItem().exists()).toBe(false);
      });
    });

    describe('when available', () => {
      beforeEach(() => {
        createShallowWrapper();
      });

      it('modal for custom metrics form is rendered', () => {
        expect(findAddMetricModal().exists()).toBe(true);
        expect(findAddMetricModal().props('modalId')).toBe('addMetric');
      });

      it('add metric modal submit button exists', () => {
        expect(findAddMetricModalSubmitButton().exists()).toBe(true);
      });

      it('renders custom metrics form fields', () => {
        expect(wrapper.find(CustomMetricsFormFields).exists()).toBe(true);
      });
    });

    describe('when not available', () => {
      beforeEach(() => {
        createShallowWrapper({ addingMetricsAvailable: false });
      });

      it('modal for custom metrics form is not rendered', () => {
        expect(findAddMetricModal().exists()).toBe(false);
      });
    });

    describe('adding new metric from modal', () => {
      let origPage;

      beforeEach((done) => {
        jest.spyOn(Tracking, 'event').mockReturnValue();
        createShallowWrapper();

        setupStoreWithData(store);

        origPage = document.body.dataset.page;
        document.body.dataset.page = 'projects:environments:metrics';

        wrapper.vm.$nextTick(done);
      });

      afterEach(() => {
        document.body.dataset.page = origPage;
      });

      it('is tracked', (done) => {
        const submitButton = findAddMetricModalSubmitButton().vm;

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
    });
  });

  describe('add panel item', () => {
    const GlDropdownItemStub = {
      extends: GlDropdownItem,
      props: {
        to: [String, Object],
      },
    };

    let $route;

    beforeEach(() => {
      $route = { name: DASHBOARD_PAGE, params: { dashboard: 'my_dashboard.yml' } };

      createShallowWrapper(
        {
          isOotbDashboard: false,
        },
        {
          mocks: { $route },
          stubs: { GlDropdownItem: GlDropdownItemStub },
        },
      );
    });

    it('is disabled for ootb dashboards', () => {
      createShallowWrapper({
        isOotbDashboard: true,
      });

      return wrapper.vm.$nextTick(() => {
        expect(findAddPanelItemDisabled().exists()).toBe(true);
      });
    });

    it('is visible for custom dashboards', () => {
      expect(findAddPanelItemEnabled().exists()).toBe(true);
    });

    it('renders a link to the new panel page for custom dashboards', () => {
      expect(findAddPanelItemEnabled().props('to')).toEqual({
        name: PANEL_NEW_PAGE,
        params: {
          dashboard: 'my_dashboard.yml',
        },
      });
    });
  });

  describe('edit dashboard yml item', () => {
    beforeEach(() => {
      createShallowWrapper();
    });

    describe('when current dashboard is custom', () => {
      beforeEach(() => {
        setupAllDashboards(store, customDashboard.path);
      });

      it('enabled item is rendered and has falsy disabled attribute', () => {
        expect(findEditDashboardItemEnabled().exists()).toBe(true);
        expect(findEditDashboardItemEnabled().attributes('disabled')).toBe(undefined);
      });

      it('enabled item links to their edit path', () => {
        expect(findEditDashboardItemEnabled().attributes('href')).toBe(
          customDashboard.project_blob_path,
        );
      });

      it('disabled item is not rendered', () => {
        expect(findEditDashboardItemDisabled().exists()).toBe(false);
      });
    });

    describe.each(ootbDashboards)('when current dashboard is OOTB', (dashboard) => {
      beforeEach(() => {
        setupAllDashboards(store, dashboard.path);
      });

      it('disabled item is rendered and has disabled attribute set on it', () => {
        expect(findEditDashboardItemDisabled().exists()).toBe(true);
        expect(findEditDashboardItemDisabled().attributes('disabled')).toBe('');
      });

      it('enabled item is not rendered', () => {
        expect(findEditDashboardItemEnabled().exists()).toBe(false);
      });
    });
  });

  describe('duplicate dashboard item', () => {
    beforeEach(() => {
      createShallowWrapper();
    });

    describe.each(ootbDashboards)('when current dashboard is OOTB', (dashboard) => {
      beforeEach(() => {
        setupAllDashboards(store, dashboard.path);
      });

      it('is rendered', () => {
        expect(findDuplicateDashboardItem().exists()).toBe(true);
      });

      it('duplicate dashboard modal is rendered', () => {
        expect(findDuplicateDashboardModal().exists()).toBe(true);
      });

      it('clicking on item opens up the duplicate dashboard modal', () => {
        const modalId = 'duplicateDashboard';
        const modalTrigger = findDuplicateDashboardItem();
        const rootEmit = jest.spyOn(wrapper.vm.$root, '$emit');

        modalTrigger.trigger('click');

        return wrapper.vm.$nextTick().then(() => {
          expect(rootEmit.mock.calls[0]).toContainEqual(modalId);
        });
      });
    });

    describe('when current dashboard is custom', () => {
      beforeEach(() => {
        setupAllDashboards(store, customDashboard.path);
      });

      it('is not rendered', () => {
        expect(findDuplicateDashboardItem().exists()).toBe(false);
      });

      it('duplicate dashboard modal is not rendered', () => {
        expect(findDuplicateDashboardModal().exists()).toBe(false);
      });
    });

    describe('when no dashboard is set', () => {
      it('is not rendered', () => {
        expect(findDuplicateDashboardItem().exists()).toBe(false);
      });

      it('duplicate dashboard modal is not rendered', () => {
        expect(findDuplicateDashboardModal().exists()).toBe(false);
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

        const newDashboardUrl = 'root/sandbox/-/metrics/dashboard.yml';
        findDuplicateDashboardModal().vm.$emit('dashboardDuplicated', newDashboard);

        return wrapper.vm.$nextTick().then(() => {
          expect(redirectTo).toHaveBeenCalled();
          expect(redirectTo).toHaveBeenCalledWith(newDashboardUrl);
        });
      });
    });
  });

  describe('star dashboard item', () => {
    beforeEach(() => {
      createShallowWrapper();
      setupAllDashboards(store);

      jest.spyOn(store, 'dispatch').mockResolvedValue();
    });

    it('is shown', () => {
      expect(findStarDashboardItem().exists()).toBe(true);
    });

    it('is not disabled', () => {
      expect(findStarDashboardItem().attributes('disabled')).toBeFalsy();
    });

    it('is disabled when starring is taking place', () => {
      store.commit(`monitoringDashboard/${types.REQUEST_DASHBOARD_STARRING}`);

      return wrapper.vm.$nextTick(() => {
        expect(findStarDashboardItem().exists()).toBe(true);
        expect(findStarDashboardItem().attributes('disabled')).toBe('true');
      });
    });

    it('on click it dispatches a toggle star action', () => {
      findStarDashboardItem().vm.$emit('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(store.dispatch).toHaveBeenCalledWith(
          'monitoringDashboard/toggleStarredValue',
          undefined,
        );
      });
    });

    describe('when dashboard is not starred', () => {
      beforeEach(() => {
        store.commit(`monitoringDashboard/${types.SET_INITIAL_STATE}`, {
          currentDashboard: dashboardGitResponse[0].path,
        });
        return wrapper.vm.$nextTick();
      });

      it('item text shows "Star dashboard"', () => {
        expect(findStarDashboardItem().html()).toMatch(/Star dashboard/);
      });
    });

    describe('when dashboard is starred', () => {
      beforeEach(() => {
        store.commit(`monitoringDashboard/${types.SET_INITIAL_STATE}`, {
          currentDashboard: dashboardGitResponse[1].path,
        });
        return wrapper.vm.$nextTick();
      });

      it('item text shows "Unstar dashboard"', () => {
        expect(findStarDashboardItem().html()).toMatch(/Unstar dashboard/);
      });
    });
  });

  describe('create dashboard item', () => {
    beforeEach(() => {
      createShallowWrapper();
    });

    it('is rendered by default but it is disabled', () => {
      expect(findCreateDashboardItem().attributes('disabled')).toBe('true');
    });

    describe('when project path is set', () => {
      const mockProjectPath = 'root/sandbox';
      const mockAddDashboardDocPath = '/doc/add-dashboard';

      beforeEach(() => {
        store.state.monitoringDashboard.projectPath = mockProjectPath;
        store.state.monitoringDashboard.addDashboardDocumentationPath = mockAddDashboardDocPath;
      });

      it('is not disabled', () => {
        expect(findCreateDashboardItem().attributes('disabled')).toBe(undefined);
      });

      it('renders a modal for creating a dashboard', () => {
        expect(findCreateDashboardModal().exists()).toBe(true);
      });

      it('clicking opens up the modal', () => {
        const modalId = 'createDashboard';
        const modalTrigger = findCreateDashboardItem();
        const rootEmit = jest.spyOn(wrapper.vm.$root, '$emit');

        modalTrigger.trigger('click');

        return wrapper.vm.$nextTick().then(() => {
          expect(rootEmit.mock.calls[0]).toContainEqual(modalId);
        });
      });

      it('modal gets passed correct props', () => {
        expect(findCreateDashboardModal().props('projectPath')).toBe(mockProjectPath);
        expect(findCreateDashboardModal().props('addDashboardDocumentationPath')).toBe(
          mockAddDashboardDocPath,
        );
      });
    });

    describe('when project path is not set', () => {
      beforeEach(() => {
        store.state.monitoringDashboard.projectPath = null;
      });

      it('is disabled', () => {
        expect(findCreateDashboardItem().attributes('disabled')).toBe('true');
      });

      it('does not render a modal for creating a dashboard', () => {
        expect(findCreateDashboardModal().exists()).toBe(false);
      });
    });
  });
});
