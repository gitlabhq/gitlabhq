import { mount, createLocalVue } from '@vue/test-utils';
import VueRouter from 'vue-router';
import DashboardPage from '~/monitoring/pages/dashboard_page.vue';
import Dashboard from '~/monitoring/components/dashboard.vue';
import { createStore } from '~/monitoring/stores';
import createRouter from '~/monitoring/router';
import { dashboardProps } from './fixture_data';
import { dashboardHeaderProps } from './mock_data';

describe('Monitoring router', () => {
  let router;
  let store;
  const propsData = { dashboardProps: { ...dashboardProps, ...dashboardHeaderProps } };
  const NEW_BASE_PATH = '/project/my-group/test-project/-/metrics';
  const OLD_BASE_PATH = '/project/my-group/test-project/-/environments/71146/metrics';

  const createWrapper = (basePath, routeArg) => {
    const localVue = createLocalVue();
    localVue.use(VueRouter);

    router = createRouter(basePath);
    if (routeArg !== undefined) {
      router.push(routeArg);
    }

    return mount(DashboardPage, {
      localVue,
      store,
      router,
      propsData,
    });
  };

  beforeEach(() => {
    store = createStore();
    jest.spyOn(store, 'dispatch').mockResolvedValue();
  });

  afterEach(() => {
    window.location.hash = '';
  });

  describe('support old URL with full dashboard path', () => {
    it.each`
      route                          | currentDashboard
      ${'/dashboard.yml'}            | ${'dashboard.yml'}
      ${'/folder1/dashboard.yml'}    | ${'folder1/dashboard.yml'}
      ${'/?dashboard=dashboard.yml'} | ${'dashboard.yml'}
    `('sets component as $componentName for path "$route"', ({ route, currentDashboard }) => {
      const wrapper = createWrapper(OLD_BASE_PATH, route);

      expect(store.dispatch).toHaveBeenCalledWith('monitoringDashboard/setCurrentDashboard', {
        currentDashboard,
      });

      expect(wrapper.find(Dashboard)).toExist();
    });
  });

  describe('supports new URL with short dashboard path', () => {
    it.each`
      route                                       | currentDashboard
      ${'/'}                                      | ${null}
      ${'/dashboard.yml'}                         | ${'dashboard.yml'}
      ${'/folder1/dashboard.yml'}                 | ${'folder1/dashboard.yml'}
      ${'/folder1%2Fdashboard.yml'}               | ${'folder1/dashboard.yml'}
      ${'/dashboard.yml'}                         | ${'dashboard.yml'}
      ${'/config/prometheus/common_metrics.yml'}  | ${'config/prometheus/common_metrics.yml'}
      ${'/config/prometheus/pod_metrics.yml'}     | ${'config/prometheus/pod_metrics.yml'}
      ${'/config%2Fprometheus%2Fpod_metrics.yml'} | ${'config/prometheus/pod_metrics.yml'}
    `('sets component as $componentName for path "$route"', ({ route, currentDashboard }) => {
      const wrapper = createWrapper(NEW_BASE_PATH, route);

      expect(store.dispatch).toHaveBeenCalledWith('monitoringDashboard/setCurrentDashboard', {
        currentDashboard,
      });

      expect(wrapper.find(Dashboard)).toExist();
    });
  });
});
