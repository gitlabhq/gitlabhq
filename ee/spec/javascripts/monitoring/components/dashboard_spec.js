import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import Dashboard from '~/monitoring/components/dashboard.vue';
import axios from '~/lib/utils/axios_utils';
import { metricsGroupsAPIResponse, mockApiEndpoint } from 'spec/monitoring/mock_data';
import propsData from 'spec/monitoring/dashboard_spec';

describe('Dashboard', () => {
  let Component;
  let mock;
  let vm;

  beforeEach(() => {
    setFixtures(`
      <div class="prometheus-graphs"></div>
      <div class="nav-sidebar"></div>
    `);
    mock = new MockAdapter(axios);
    Component = Vue.extend(Dashboard);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('metrics without alerts', () => {
    it('does not show threshold lines', (done) => {
      vm = new Component({
        el: document.querySelector('.prometheus-graphs'),
        propsData: {
          ...propsData,
          hasMetrics: true,
        },
      });

      setTimeout(() => {
        expect(vm.$el).not.toContainElement('.js-threshold-lines');
        done();
      });
    });
  });

  describe('metrics with alert', () => {
    const metricId = 5;
    const alertParams = {
      operator: '<',
      threshold: 4,
      prometheus_metric_id: metricId,
    };

    beforeEach(() => {
      mock.onGet(mockApiEndpoint).reply(200, metricsGroupsAPIResponse);
      vm = new Component({
        el: document.querySelector('.prometheus-graphs'),
        propsData: {
          ...propsData,
          hasMetrics: true,
        },
      });
    });

    it('shows single threshold line', (done) => {
      vm.setAlerts(metricId, {
        alertName: alertParams,
      });

      setTimeout(() => {
        expect(vm.$el.querySelectorAll('.js-threshold-lines').length).toEqual(1);
        done();
      });
    });

    it('shows multiple threshold lines', (done) => {
      vm.setAlerts(metricId, {
        someAlert: alertParams,
        otherAlert: alertParams,
      });

      setTimeout(() => {
        expect(vm.$el.querySelectorAll('.js-threshold-lines').length).toEqual(2);
        done();
      });
    });
  });
});
