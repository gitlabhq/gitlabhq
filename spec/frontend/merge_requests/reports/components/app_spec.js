import Vue from 'vue';
import VueRouter from 'vue-router';
import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import MRWidgetService from 'ee_else_ce/vue_merge_request_widget/services/mr_widget_service';
import SmartInterval from '~/smart_interval';
import StatusIcon from '~/vue_merge_request_widget/components/widget/status_icon.vue';
import App from '~/merge_requests/reports/components/app.vue';
import routes from '~/merge_requests/reports/routes';

jest.mock('ee_else_ce/vue_merge_request_widget/services/mr_widget_service', () => ({
  fetchInitialData: jest.fn().mockReturnValue(new Promise(() => {})),
}));

jest.mock('~/smart_interval');

Vue.use(VueRouter);

describe('Merge request reports App component', () => {
  let wrapper;

  const findSecurityScansProvider = () => wrapper.findComponent({ name: 'SecurityScansProvider' });
  const findSecurityNavItem = () => wrapper.findComponent({ name: 'SecurityNavItem' });
  const findLicenseComplianceProvider = () =>
    wrapper.findComponent({ name: 'LicenseComplianceProvider' });
  const findLicenseComplianceNavItem = () =>
    wrapper.findComponent({ name: 'LicenseComplianceNavItem' });
  const findCodeQualityProvider = () => wrapper.findComponent({ name: 'CodeQualityProvider' });
  const findCodeQualityNavItem = () => wrapper.findComponent({ name: 'CodeQualityNavItem' });
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findStatusIcon = () => wrapper.findComponent(StatusIcon);
  const findKeepAlive = () => wrapper.findByTestId('keep-alive');
  const findRouterView = () => wrapper.findComponent({ name: 'RouterView' });
  const findStatusMessage = () => wrapper.findByTestId('status-message');

  const expectProvidersToExist = (exists) => {
    expect(findSecurityScansProvider().exists()).toBe(exists);
    expect(findLicenseComplianceProvider().exists()).toBe(exists);
    expect(findCodeQualityProvider().exists()).toBe(exists);
  };

  const expectNavItemsToExist = (exists) => {
    expect(findSecurityNavItem().exists()).toBe(exists);
    expect(findLicenseComplianceNavItem().exists()).toBe(exists);
    expect(findCodeQualityNavItem().exists()).toBe(exists);
  };

  const mockNoPipeline = () => {
    MRWidgetService.fetchInitialData.mockResolvedValue({
      data: { current_user: {} },
    });
  };

  const mockPipeline = (active) => {
    MRWidgetService.fetchInitialData.mockResolvedValue({
      data: {
        current_user: {},
        pipeline: { active, iid: 1, details: { status: {} } },
      },
    });
  };

  const createComponent = () => {
    gl.mrWidgetData = {
      merge_request_cached_widget_path: '/',
      merge_request_widget_path: '/',
    };

    const router = new VueRouter({ mode: 'history', routes });
    wrapper = shallowMountExtended(App, {
      router,
      provide: {
        hasPolicies: false,
        projectPath: 'gitlab-org/gitlab',
        iid: '1',
      },
      stubs: {
        'keep-alive': {
          template: '<div data-testid="keep-alive"><slot /></div>',
        },
        SecurityScansProvider: {
          name: 'SecurityScansProvider',
          template: '<div><slot /></div>',
        },
        SecurityNavItem: {
          name: 'SecurityNavItem',
          template: '<div></div>',
        },
        LicenseComplianceProvider: {
          name: 'LicenseComplianceProvider',
          template: '<div><slot /></div>',
        },
        LicenseComplianceNavItem: {
          name: 'LicenseComplianceNavItem',
          template: '<div></div>',
        },
        CodeQualityProvider: {
          name: 'CodeQualityProvider',
          template: '<div><slot /></div>',
        },
        CodeQualityNavItem: {
          name: 'CodeQualityNavItem',
          template: '<div></div>',
        },
      },
    });
  };

  afterEach(() => {
    gl.mrWidgetData = {};
  });

  describe('when no MR data', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('does not render router-view', () => {
      expect(findRouterView().exists()).toBe(false);
    });

    it('does not render providers', () => {
      expectProvidersToExist(false);
    });

    it('does not render nav items', () => {
      expectNavItemsToExist(false);
    });
  });

  describe('when no pipeline exists', () => {
    beforeEach(async () => {
      mockNoPipeline();
      createComponent();
      await waitForPromises();
    });

    it('shows status message', () => {
      expect(findStatusMessage().text()).toContain(
        'No pipelines started yet. Results will appear when a pipeline completes.',
      );
    });

    it('does not show loading status icon', () => {
      expect(findStatusIcon().exists()).toBe(false);
    });

    it('does not render router-view', () => {
      expect(findRouterView().exists()).toBe(false);
    });

    it('does not render providers', () => {
      expectProvidersToExist(false);
    });

    it('does not render nav items', () => {
      expectNavItemsToExist(false);
    });
  });

  describe('when pipeline is running', () => {
    beforeEach(async () => {
      mockPipeline(true);
      createComponent();
      await waitForPromises();
    });

    it('shows status message', () => {
      expect(findStatusMessage().text()).toContain('Waiting for pipeline to complete');
    });

    it('shows loading status icon', () => {
      expect(findStatusIcon().props('isLoading')).toBe(true);
    });

    it('does not render router-view', () => {
      expect(findRouterView().exists()).toBe(false);
    });

    it('does not render providers', () => {
      expectProvidersToExist(false);
    });

    it('does not render nav items', () => {
      expectNavItemsToExist(false);
    });
  });

  describe('when pipeline is complete', () => {
    beforeEach(async () => {
      mockPipeline(false);
      createComponent();
      await waitForPromises();
    });

    it('renders router-view', () => {
      expect(findRouterView().exists()).toBe(true);
    });

    it('keeps the report view mounted so users do not re-fetch data when switching tabs', () => {
      expect(findKeepAlive().exists()).toBe(true);
      expect(findKeepAlive().findComponent({ name: 'RouterView' }).exists()).toBe(true);
    });

    it('does not show status message', () => {
      expect(findStatusMessage().isVisible()).toBe(false);
    });

    it('does not show loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('renders providers', () => {
      expectProvidersToExist(true);
    });

    it('renders nav items', () => {
      expectNavItemsToExist(true);
    });
  });

  describe('MR data polling', () => {
    it('starts polling when pipeline is active', async () => {
      mockPipeline(true);
      createComponent();
      await waitForPromises();

      expect(SmartInterval).toHaveBeenCalledWith(
        expect.objectContaining({
          callback: expect.any(Function),
          startingInterval: 5000,
          maxInterval: 120000,
          incrementByFactorOf: 2,
          immediateExecution: false,
        }),
      );
    });

    it('starts polling when no pipeline exists', async () => {
      mockNoPipeline();
      createComponent();
      await waitForPromises();

      expect(SmartInterval).toHaveBeenCalledWith(
        expect.objectContaining({
          callback: expect.any(Function),
        }),
      );
    });

    it('does not start polling when pipeline is complete', async () => {
      mockPipeline(false);
      createComponent();
      await waitForPromises();

      expect(SmartInterval).not.toHaveBeenCalled();
    });

    it('cleans up polling on destroy', async () => {
      const destroy = jest.fn();
      SmartInterval.mockImplementation(() => ({ destroy }));
      mockPipeline(true);
      createComponent();
      await waitForPromises();

      wrapper.destroy();

      expect(destroy).toHaveBeenCalled();
    });
  });
});
