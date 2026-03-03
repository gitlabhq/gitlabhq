import Vue from 'vue';
import VueRouter from 'vue-router';
import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import MRWidgetService from 'ee_else_ce/vue_merge_request_widget/services/mr_widget_service';
import SmartInterval from '~/smart_interval';
import App from '~/merge_requests/reports/components/app.vue';
import routes from '~/merge_requests/reports/routes';

jest.mock('ee_else_ce/vue_merge_request_widget/services/mr_widget_service', () => ({
  fetchInitialData: jest.fn().mockResolvedValue({ data: { current_user: {} } }),
}));

jest.mock('~/smart_interval');

Vue.use(VueRouter);

describe('Merge request reports App component', () => {
  let wrapper;

  const findSecurityScansProvider = () => wrapper.findComponent({ name: 'SecurityScansProvider' });
  const findSecurityNavItem = () => wrapper.findComponent({ name: 'SecurityNavItem' });
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findRouterView = () => wrapper.findComponent({ name: 'RouterView' });

  const createComponent = () => {
    const router = new VueRouter({ mode: 'history', routes });
    wrapper = shallowMountExtended(App, {
      router,
      provide: {
        hasPolicies: false,
        projectPath: 'gitlab-org/gitlab',
        iid: '1',
      },
      stubs: {
        SecurityScansProvider: {
          name: 'SecurityScansProvider',
          template: '<div><slot /></div>',
        },
        SecurityNavItem: {
          name: 'SecurityNavItem',
          template: '<div></div>',
        },
      },
    });
  };

  beforeEach(() => {
    window.gl = {
      mrWidgetData: { merge_request_cached_widget_path: '/', merge_request_widget_path: '/' },
    };
  });

  afterEach(() => {
    window.gl = {};
  });

  it('renders SecurityScansProvider when mr is loaded', async () => {
    createComponent();

    await waitForPromises();

    expect(findSecurityScansProvider().exists()).toBe(true);
  });

  it('renders SecurityNavItem inside provider', async () => {
    createComponent();

    await waitForPromises();

    expect(findSecurityNavItem().exists()).toBe(true);
  });

  it('shows loading icon when mr is not loaded', () => {
    createComponent();

    expect(findLoadingIcon().exists()).toBe(true);
    expect(findRouterView().exists()).toBe(false);
  });

  it('shows router-view when mr is loaded', async () => {
    createComponent();

    await waitForPromises();

    expect(findLoadingIcon().exists()).toBe(false);
    expect(findRouterView().exists()).toBe(true);
  });

  describe('MR data polling', () => {
    const mockActivePipeline = () => {
      MRWidgetService.fetchInitialData.mockResolvedValue({
        data: { current_user: {}, pipeline: { active: true, details: { status: {} } } },
      });
    };

    afterEach(() => {
      MRWidgetService.fetchInitialData.mockResolvedValue({ data: { current_user: {} } });
    });

    it('starts polling when pipeline is active', async () => {
      mockActivePipeline();
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

    it('does not start polling when pipeline is not active', async () => {
      createComponent();
      await waitForPromises();

      expect(SmartInterval).not.toHaveBeenCalled();
    });

    it('cleans up polling on destroy', async () => {
      const destroy = jest.fn();
      SmartInterval.mockImplementation(() => ({ destroy }));
      mockActivePipeline();
      createComponent();
      await waitForPromises();

      wrapper.destroy();

      expect(destroy).toHaveBeenCalled();
    });
  });
});
