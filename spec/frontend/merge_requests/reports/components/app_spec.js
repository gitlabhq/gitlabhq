import Vue from 'vue';
import VueRouter from 'vue-router';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
// import MRWidgetService from 'ee_else_ce/vue_merge_request_widget/services/mr_widget_service';
import App from '~/merge_requests/reports/components/app.vue';
import routes from '~/merge_requests/reports/routes';

jest.mock('ee_else_ce/vue_merge_request_widget/services/mr_widget_service', () => ({
  fetchInitialData: jest.fn().mockResolvedValue({ data: { current_user: {} } }),
}));

Vue.use(VueRouter);

describe('Merge request reports App component', () => {
  let wrapper;

  const findReportsWidget = () => wrapper.findByTestId('reports-widget-sidebar');

  const createComponent = () => {
    const router = new VueRouter({ mode: 'history', routes });
    wrapper = shallowMountExtended(App, { router, provide: { hasPolicies: false } });
  };

  beforeEach(() => {
    window.gl = {
      mrWidgetData: { merge_request_cached_widget_path: '/', merge_request_widget_path: '/' },
    };
  });

  afterEach(() => {
    window.gl = {};
  });

  it('renders report widget in sidebar', async () => {
    createComponent();

    await waitForPromises();

    expect(findReportsWidget().exists()).toBe(true);
  });
});
