import { mount, createLocalVue } from '@vue/test-utils';
import VueRouter from 'vue-router';
import Dashboard from '~/monitoring/components/dashboard.vue';
import DashboardPage from '~/monitoring/pages/dashboard_page.vue';
import PanelNewPage from '~/monitoring/pages/panel_new_page.vue';
import createRouter from '~/monitoring/router';
import { createStore } from '~/monitoring/stores';
import { dashboardProps } from './fixture_data';
import { dashboardHeaderProps } from './mock_data';

const LEGACY_BASE_PATH = '/project/my-group/test-project/-/environments/71146/metrics';
const BASE_PATH = '/project/my-group/test-project/-/metrics';

const MockApp = {
  data() {
    return {
      dashboardProps: { ...dashboardProps, ...dashboardHeaderProps },
    };
  },
  template: `<router-view  :dashboard-props="dashboardProps"/>`,
};

const provide = { hasManagedPrometheus: false };

describe('Monitoring router', () => {
  let router;
  let store;

  const createWrapper = (basePath, routeArg) => {
    const localVue = createLocalVue();
    localVue.use(VueRouter);

    router = createRouter(basePath);
    if (routeArg !== undefined) {
      router.push(routeArg);
    }

    return mount(MockApp, {
      localVue,
      store,
      router,
      provide,
    });
  };

  beforeEach(() => {
    store = createStore();
    jest.spyOn(store, 'dispatch').mockResolvedValue();
  });

  afterEach(() => {
    window.location.hash = '';
  });

  describe('support legacy URLs with full dashboard path to visit dashboard page', () => {
    it.each`
      path                           | currentDashboard
      ${'/dashboard.yml'}            | ${'dashboard.yml'}
      ${'/folder1/dashboard.yml'}    | ${'folder1/dashboard.yml'}
      ${'/?dashboard=dashboard.yml'} | ${'dashboard.yml'}
    `('"$path" renders page with dashboard "$currentDashboard"', ({ path, currentDashboard }) => {
      const wrapper = createWrapper(LEGACY_BASE_PATH, path);

      expect(store.dispatch).toHaveBeenCalledWith('monitoringDashboard/setCurrentDashboard', {
        currentDashboard,
      });

      expect(wrapper.find(DashboardPage).exists()).toBe(true);
      expect(wrapper.find(DashboardPage).find(Dashboard).exists()).toBe(true);
    });
  });

  describe('supports URLs to visit dashboard page', () => {
    it.each`
      path                                        | currentDashboard
      ${'/'}                                      | ${null}
      ${'/dashboard.yml'}                         | ${'dashboard.yml'}
      ${'/folder1/dashboard.yml'}                 | ${'folder1/dashboard.yml'}
      ${'/folder1%2Fdashboard.yml'}               | ${'folder1/dashboard.yml'}
      ${'/dashboard.yml'}                         | ${'dashboard.yml'}
      ${'/config/prometheus/common_metrics.yml'}  | ${'config/prometheus/common_metrics.yml'}
      ${'/config/prometheus/pod_metrics.yml'}     | ${'config/prometheus/pod_metrics.yml'}
      ${'/config%2Fprometheus%2Fpod_metrics.yml'} | ${'config/prometheus/pod_metrics.yml'}
    `('"$path" renders page with dashboard "$currentDashboard"', ({ path, currentDashboard }) => {
      const wrapper = createWrapper(BASE_PATH, path);

      expect(store.dispatch).toHaveBeenCalledWith('monitoringDashboard/setCurrentDashboard', {
        currentDashboard,
      });

      expect(wrapper.find(DashboardPage).exists()).toBe(true);
      expect(wrapper.find(DashboardPage).find(Dashboard).exists()).toBe(true);
    });
  });

  describe('supports URLs to visit new panel page', () => {
    it.each`
      path                                                     | currentDashboard
      ${'/panel/new'}                                          | ${undefined}
      ${'/dashboard.yml/panel/new'}                            | ${'dashboard.yml'}
      ${'/config/prometheus/common_metrics.yml/panel/new'}     | ${'config/prometheus/common_metrics.yml'}
      ${'/config%2Fprometheus%2Fcommon_metrics.yml/panel/new'} | ${'config/prometheus/common_metrics.yml'}
    `('"$path" renders page with dashboard "$currentDashboard"', ({ path, currentDashboard }) => {
      const wrapper = createWrapper(BASE_PATH, path);

      expect(wrapper.vm.$route.params.dashboard).toBe(currentDashboard);
      expect(wrapper.find(PanelNewPage).exists()).toBe(true);
    });
  });
});
