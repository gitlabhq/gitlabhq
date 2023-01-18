import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import Vue, { nextTick } from 'vue';
import waitForPromises from 'helpers/wait_for_promises';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import MemoryUsage from '~/vue_merge_request_widget/components/deployment/memory_usage.vue';
import MRWidgetService from '~/vue_merge_request_widget/services/mr_widget_service';

const url = '/root/acets-review-apps/environments/15/deployments/1/metrics';
const monitoringUrl = '/root/acets-review-apps/environments/15/metrics';

const metricsMockData = {
  success: true,
  metrics: {
    memory_before: [
      {
        metric: {},
        value: [1495785220.607, '9572875.906976745'],
      },
    ],
    memory_after: [
      {
        metric: {},
        value: [1495787020.607, '4485853.130206379'],
      },
    ],
    memory_values: [
      {
        metric: {},
        values: [[1493716685, '4.30859375']],
      },
    ],
  },
  last_update: '2017-05-02T12:34:49.628Z',
  deployment_time: 1493718485,
};

const createComponent = () => {
  const Component = Vue.extend(MemoryUsage);

  return new Component({
    el: document.createElement('div'),
    propsData: {
      metricsUrl: url,
      metricsMonitoringUrl: monitoringUrl,
      memoryMetrics: [],
      deploymentTime: 0,
      hasMetrics: false,
      loadFailed: false,
      loadingMetrics: true,
      backOffRequestCounter: 0,
    },
  });
};

const messages = {
  loadingMetrics: 'Loading deployment statistics',
  hasMetrics: 'Memory  usage is  unchanged  at 0MB',
  loadFailed: 'Failed to load deployment statistics',
  metricsUnavailable: 'Deployment statistics are not available currently',
};

describe('MemoryUsage', () => {
  let vm;
  let el;
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onGet(`${url}.json`).reply(HTTP_STATUS_OK);

    vm = createComponent();
    el = vm.$el;
  });

  afterEach(() => {
    mock.restore();
  });

  describe('data', () => {
    it('should have default data', () => {
      const data = MemoryUsage.data();

      expect(Array.isArray(data.memoryMetrics)).toBe(true);
      expect(data.memoryMetrics.length).toBe(0);

      expect(typeof data.deploymentTime).toBe('number');
      expect(data.deploymentTime).toBe(0);

      expect(typeof data.hasMetrics).toBe('boolean');
      expect(data.hasMetrics).toBe(false);

      expect(typeof data.loadFailed).toBe('boolean');
      expect(data.loadFailed).toBe(false);

      expect(typeof data.loadingMetrics).toBe('boolean');
      expect(data.loadingMetrics).toBe(true);

      expect(typeof data.backOffRequestCounter).toBe('number');
      expect(data.backOffRequestCounter).toBe(0);
    });
  });

  describe('computed', () => {
    describe('memoryChangeMessage', () => {
      it('should contain "increased" if memoryFrom value is less than memoryTo value', () => {
        vm.memoryFrom = 4.28;
        vm.memoryTo = 9.13;

        expect(vm.memoryChangeMessage.indexOf('increased')).not.toEqual('-1');
      });

      it('should contain "decreased" if memoryFrom value is less than memoryTo value', () => {
        vm.memoryFrom = 9.13;
        vm.memoryTo = 4.28;

        expect(vm.memoryChangeMessage.indexOf('decreased')).not.toEqual('-1');
      });

      it('should contain "unchanged" if memoryFrom value equal to memoryTo value', () => {
        vm.memoryFrom = 1;
        vm.memoryTo = 1;

        expect(vm.memoryChangeMessage.indexOf('unchanged')).not.toEqual('-1');
      });
    });
  });

  describe('methods', () => {
    const { metrics, deployment_time } = metricsMockData;

    describe('getMegabytes', () => {
      it('should return Megabytes from provided Bytes value', () => {
        const memoryInBytes = '9572875.906976745';

        expect(vm.getMegabytes(memoryInBytes)).toEqual('9.13');
      });
    });

    describe('computeGraphData', () => {
      it('should populate sparkline graph', () => {
        // ignore BoostrapVue warnings
        jest.spyOn(console, 'warn').mockImplementation();

        vm.computeGraphData(metrics, deployment_time);
        const { hasMetrics, memoryMetrics, deploymentTime, memoryFrom, memoryTo } = vm;

        expect(hasMetrics).toBe(true);
        expect(memoryMetrics.length).toBeGreaterThan(0);
        expect(deploymentTime).toEqual(deployment_time);
        expect(memoryFrom).toEqual('9.13');
        expect(memoryTo).toEqual('4.28');
      });
    });

    describe('loadMetrics', () => {
      it('should load metrics data using MRWidgetService', async () => {
        jest.spyOn(MRWidgetService, 'fetchMetrics').mockResolvedValue({
          data: metricsMockData,
        });
        jest.spyOn(vm, 'computeGraphData').mockImplementation(() => {});

        vm.loadMetrics();

        await waitForPromises();

        expect(MRWidgetService.fetchMetrics).toHaveBeenCalledWith(url);
        expect(vm.computeGraphData).toHaveBeenCalledWith(metrics, deployment_time);
      });
    });
  });

  describe('template', () => {
    it('should render template elements correctly', () => {
      expect(el.classList.contains('mr-memory-usage')).toBe(true);
      expect(el.querySelector('.js-usage-info')).toBeDefined();
    });

    it('should show loading metrics message while metrics are being loaded', async () => {
      vm.loadingMetrics = true;
      vm.hasMetrics = false;
      vm.loadFailed = false;

      await nextTick();

      expect(el.querySelector('.js-usage-info.usage-info-loading')).toBeDefined();
      expect(el.querySelector('.js-usage-info .usage-info-load-spinner')).toBeDefined();
      expect(el.querySelector('.js-usage-info').innerText).toContain(messages.loadingMetrics);
    });

    it('should show deployment memory usage when metrics are loaded', async () => {
      // ignore BoostrapVue warnings
      jest.spyOn(console, 'warn').mockImplementation();

      vm.loadingMetrics = false;
      vm.hasMetrics = true;
      vm.loadFailed = false;
      vm.memoryMetrics = metricsMockData.metrics.memory_values[0].values;

      await nextTick();

      expect(el.querySelector('.memory-graph-container')).toBeDefined();
      expect(el.querySelector('.js-usage-info').innerText).toContain(messages.hasMetrics);
    });

    it('should show failure message when metrics loading failed', async () => {
      vm.loadingMetrics = false;
      vm.hasMetrics = false;
      vm.loadFailed = true;

      await nextTick();

      expect(el.querySelector('.js-usage-info.usage-info-failed')).toBeDefined();
      expect(el.querySelector('.js-usage-info').innerText).toContain(messages.loadFailed);
    });

    it('should show metrics unavailable message when metrics loading failed', async () => {
      vm.loadingMetrics = false;
      vm.hasMetrics = false;
      vm.loadFailed = false;

      await nextTick();

      expect(el.querySelector('.js-usage-info.usage-info-unavailable')).toBeDefined();
      expect(el.querySelector('.js-usage-info').innerText).toContain(messages.metricsUnavailable);
    });
  });
});
