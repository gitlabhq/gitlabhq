import Vue from 'vue';
import VueRouter from 'vue-router';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import App from '~/merge_requests/reports/components/app.vue';
import routes from '~/merge_requests/reports/routes';

jest.mock('ee_else_ce/vue_merge_request_widget/services/mr_widget_service', () => ({
  fetchInitialData: jest.fn().mockResolvedValue({ data: { current_user: {} } }),
}));

Vue.use(VueRouter);

describe('Merge request reports App component', () => {
  let wrapper;

  const findSecurityScansProvider = () => wrapper.findComponent({ name: 'SecurityScansProvider' });
  const findSecurityNavItem = () => wrapper.findComponent({ name: 'SecurityNavItem' });

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
});
