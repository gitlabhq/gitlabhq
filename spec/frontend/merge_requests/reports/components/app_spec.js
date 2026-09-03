import Vue from 'vue';
import VueRouter from 'vue-router';
import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import setWindowLocation from 'helpers/set_window_location_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createEventHub from '~/helpers/event_hub_factory';
import MRWidgetService from 'ee_else_ce/vue_merge_request_widget/services/mr_widget_service';
import SmartInterval from '~/smart_interval';
import App from '~/merge_requests/reports/components/app.vue';
import ReportsEmptyState from '~/merge_requests/reports/components/reports_empty_state.vue';
import routes from '~/merge_requests/reports/routes';
import { resetMergeRequestData } from '~/merge_requests/reports/merge_request_data';

jest.mock('ee_else_ce/vue_merge_request_widget/services/mr_widget_service', () => ({
  fetchInitialData: jest.fn().mockReturnValue(new Promise(() => {})),
}));

jest.mock('~/smart_interval');

Vue.use(VueRouter);

describe('Merge request reports App component', () => {
  let wrapper;

  const findSecurityScansProvider = () => wrapper.findComponent({ name: 'SecurityScansProvider' });
  const findSecurityNavItem = () => wrapper.findComponent({ name: 'SecurityNavItem' });
  const findCodeQualityProvider = () => wrapper.findComponent({ name: 'CodeQualityProvider' });
  const findCodeQualityNavItem = () => wrapper.findComponent({ name: 'CodeQualityNavItem' });
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findKeepAlive = () => wrapper.findByTestId('keep-alive');
  const findRouterView = () => wrapper.findComponent({ name: 'RouterView' });
  const findEmptyState = () => wrapper.findComponent(ReportsEmptyState);
  const findSidebar = () => wrapper.find('aside');
  const findLiveRegion = () => wrapper.find('[role="status"]');

  const expectProvidersToExist = (exists) => {
    expect(findSecurityScansProvider().exists()).toBe(exists);
    expect(findCodeQualityProvider().exists()).toBe(exists);
  };

  const expectNavItemsToExist = (exists) => {
    expect(findSecurityNavItem().exists()).toBe(exists);
    expect(findCodeQualityNavItem().exists()).toBe(exists);
  };

  const mockNoPipeline = () => {
    MRWidgetService.fetchInitialData.mockResolvedValue({
      data: { current_user: {} },
    });
  };

  const mockPipeline = (active, data = {}) => {
    MRWidgetService.fetchInitialData.mockResolvedValue({
      data: {
        current_user: {},
        pipeline: {
          active,
          iid: 1,
          path: '/gitlab-org/gitlab/-/pipelines/1',
          details: { status: {} },
        },
        ...data,
      },
    });
  };

  const codeQualityConfigured = { codequality_reports_path: 'codequality_reports.json' };

  const emitSecurityScansChange = async (enabled) => {
    findSecurityScansProvider().vm.$emit('enabled-scans-change', enabled);
    await waitForPromises();
  };

  const createComponent = ({ initialRoute = '/', basePath = '', mrWidgetData = {} } = {}) => {
    gl.mrWidgetData = {
      merge_request_cached_widget_path: '/',
      merge_request_widget_path: '/',
      ...mrWidgetData,
    };

    const router = new VueRouter({ mode: 'history', routes });
    router.push(initialRoute).catch(() => {});
    wrapper = shallowMountExtended(App, {
      router,
      provide: {
        projectPath: 'gitlab-org/gitlab',
        iid: '1',
        basePath,
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
    resetMergeRequestData();
    gl.mrWidgetData = {};
    window.mrTabs = undefined;
  });

  describe('when no MR data', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
      expect(findEmptyState().exists()).toBe(false);
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

    it('shows the no pipeline empty state and hides the sidebar', () => {
      expect(findEmptyState().props('type')).toBe('no-pipeline');
      expect(findSidebar().isVisible()).toBe(false);
    });

    it('does not show loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(false);
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

    it('shows the running empty state with a link to the pipeline and hides the sidebar', () => {
      expect(findEmptyState().props()).toMatchObject({
        type: 'pipeline-running',
        pipelinePath: '/gitlab-org/gitlab/-/pipelines/1',
      });
      expect(findSidebar().isVisible()).toBe(false);
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
      mockPipeline(false, codeQualityConfigured);
      createComponent();
      await waitForPromises();
      await emitSecurityScansChange(true);
    });

    it('renders router-view', () => {
      expect(findRouterView().exists()).toBe(true);
    });

    it('keeps the report view mounted so users do not re-fetch data when switching tabs', () => {
      expect(findKeepAlive().exists()).toBe(true);
      expect(findKeepAlive().findComponent({ name: 'RouterView' }).exists()).toBe(true);
    });

    it('does not show an empty state', () => {
      expect(findEmptyState().exists()).toBe(false);
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

    it('navigates to the security scan route', () => {
      expect(wrapper.vm.$route.name).toBe('security-scan');
    });
  });

  describe('report configuration', () => {
    it('hides unconfigured nav items and navigates to the first configured report', async () => {
      mockPipeline(false, codeQualityConfigured);
      createComponent();
      await waitForPromises();
      await emitSecurityScansChange(false);

      expect(findSecurityNavItem().exists()).toBe(false);
      expect(findCodeQualityNavItem().exists()).toBe(true);
      expect(wrapper.vm.$route.name).toBe('code-quality');
    });

    it('shows the no reports empty state and hides the sidebar when nothing is configured', async () => {
      mockPipeline(false);
      createComponent();
      await waitForPromises();
      await emitSecurityScansChange(false);

      expectNavItemsToExist(false);
      expect(findEmptyState().props('type')).toBe('no-reports');
      expect(findSidebar().isVisible()).toBe(false);
      expect(findLiveRegion().attributes('aria-live')).toBe('polite');
      expect(findSecurityScansProvider().exists()).toBe(true);
      expect(wrapper.vm.$route.name).toBe('reports-root');
    });

    it('resets a deep-linked report URL when nothing is configured', async () => {
      mockPipeline(false);
      createComponent({ initialRoute: '/code-quality' });
      await waitForPromises();
      await emitSecurityScansChange(false);

      expect(wrapper.vm.$route.path).toBe('/');
      expect(findEmptyState().props('type')).toBe('no-reports');
    });

    it('shows the sidebar when a report is configured', async () => {
      mockPipeline(false, codeQualityConfigured);
      createComponent();
      await waitForPromises();
      await emitSecurityScansChange(false);

      expect(findSidebar().isVisible()).toBe(true);
      expect(findEmptyState().exists()).toBe(false);
    });

    it('keeps showing the loading icon until the security scan state is known', async () => {
      mockPipeline(false);
      createComponent();
      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(true);
      expect(findEmptyState().exists()).toBe(false);
    });

    it('does not navigate while the security scans state is unknown', async () => {
      mockPipeline(false, codeQualityConfigured);
      createComponent();
      await waitForPromises();

      expect(wrapper.vm.$route.path).toBe('/');
    });

    it('stays on a deep-linked report that is configured', async () => {
      mockPipeline(false, codeQualityConfigured);
      createComponent({ initialRoute: '/code-quality' });
      await waitForPromises();
      await emitSecurityScansChange(false);

      expect(wrapper.vm.$route.name).toBe('code-quality');
    });

    it('redirects a deep-linked report that is not configured to the first configured report', async () => {
      mockPipeline(false, codeQualityConfigured);
      createComponent({ initialRoute: '/security-scan' });
      await waitForPromises();
      await emitSecurityScansChange(false);

      expect(wrapper.vm.$route.name).toBe('code-quality');
    });

    it('syncs the route when polling completes the pipeline', async () => {
      mockPipeline(true);
      createComponent();
      await waitForPromises();

      mockPipeline(false);
      await SmartInterval.mock.calls[0][0].callback();
      await waitForPromises();
      await emitSecurityScansChange(true);

      expect(wrapper.vm.$route.name).toBe('security-scan');
    });

    it('does not navigate while another merge request tab is visible', async () => {
      window.mrTabs = { eventHub: createEventHub() };
      mockPipeline(false, codeQualityConfigured);
      createComponent({ basePath: '/gitlab-org/gitlab/-/merge_requests/1/reports' });
      setWindowLocation('/gitlab-org/gitlab/-/merge_requests/1');
      await waitForPromises();
      await emitSecurityScansChange(true);

      expect(wrapper.vm.$route.path).toBe('/');

      setWindowLocation('/gitlab-org/gitlab/-/merge_requests/1/reports');
      window.mrTabs.eventHub.$emit('MergeRequestTabChange', 'reports');
      await waitForPromises();

      expect(wrapper.vm.$route.name).toBe('security-scan');
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
