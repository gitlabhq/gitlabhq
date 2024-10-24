import axios from 'axios';
import { GlLoadingIcon, GlSprintf } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import MemoryUsage from '~/vue_merge_request_widget/components/deployment/memory_usage.vue';
import MRWidgetService from '~/vue_merge_request_widget/services/mr_widget_service';
import MemoryGraph from '~/vue_merge_request_widget/components/memory_graph.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

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

const messages = {
  loadingMetrics: 'Loading deployment statistics',
  hasMetrics: 'Memory  usage is  unchanged  at 0.00MB',
  loadFailed: 'Failed to load deployment statistics',
  metricsUnavailable: 'Deployment statistics are not available currently',
};

describe('MemoryUsage', () => {
  let wrapper;
  let mock;

  const createComponent = () => {
    wrapper = shallowMountExtended(MemoryUsage, {
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
      stubs: {
        GlSprintf,
      },
    });
  };

  const findGlLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findUsageInfo = () => wrapper.find('.js-usage-info');
  const findUsageInfoFailed = () => wrapper.find('.usage-info-failed');
  const findUsageInfoUnavailable = () => wrapper.find('.usage-info-unavailable');
  const findMemoryGraph = () => wrapper.findComponent(MemoryGraph);

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onGet(`${url}.json`).reply(HTTP_STATUS_OK);
  });

  describe('data', () => {
    it('should have default data', () => {
      createComponent();
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
      it('should contain "increased" if memoryFrom value is less than memoryTo value', async () => {
        jest.spyOn(MRWidgetService, 'fetchMetrics').mockResolvedValue({
          data: {
            ...metricsMockData,
            metrics: {
              ...metricsMockData.metrics,
              memory_after: [
                {
                  metric: {},
                  value: [1495787020.607, '54858853.130206379'],
                },
              ],
            },
          },
        });

        createComponent();
        await waitForPromises();

        expect(findUsageInfo().text().indexOf('increased')).not.toEqual(-1);
      });

      it('should contain "decreased" if memoryFrom value is less than memoryTo value', async () => {
        jest.spyOn(MRWidgetService, 'fetchMetrics').mockResolvedValue({
          data: metricsMockData,
        });

        createComponent();
        await waitForPromises();

        expect(findUsageInfo().text().indexOf('decreased')).not.toEqual(-1);
      });

      it('should contain "unchanged" if memoryFrom value equal to memoryTo value', async () => {
        jest.spyOn(MRWidgetService, 'fetchMetrics').mockResolvedValue({
          data: {
            ...metricsMockData,
            metrics: {
              ...metricsMockData.metrics,
              memory_after: [
                {
                  metric: {},
                  value: [1495785220.607, '9572875.906976745'],
                },
              ],
            },
          },
        });

        createComponent();
        await waitForPromises();

        expect(findUsageInfo().text().indexOf('unchanged')).not.toEqual(-1);
      });
    });
  });

  describe('methods', () => {
    beforeEach(async () => {
      jest.spyOn(MRWidgetService, 'fetchMetrics').mockResolvedValue({
        data: metricsMockData,
      });

      createComponent();
      await waitForPromises();
    });

    describe('getMegabytes', () => {
      it('should return Megabytes from provided Bytes value', () => {
        expect(findUsageInfo().text()).toContain('9.13MB');
      });
    });

    describe('computeGraphData', () => {
      it('should populate sparkline graph', () => {
        expect(findMemoryGraph().exists()).toBe(true);
        expect(findMemoryGraph().props('metrics')).toHaveLength(1);
        expect(findUsageInfo().text()).toContain('9.13MB');
        expect(findUsageInfo().text()).toContain('4.28MB');
      });
    });

    describe('loadMetrics', () => {
      beforeEach(async () => {
        createComponent();
        await waitForPromises();
      });

      it('should load metrics data using MRWidgetService', async () => {
        jest.spyOn(MRWidgetService, 'fetchMetrics').mockResolvedValue({
          data: metricsMockData,
        });

        await waitForPromises();

        expect(MRWidgetService.fetchMetrics).toHaveBeenCalledWith(url);
      });
    });
  });

  describe('template', () => {
    it('should render template elements correctly', async () => {
      jest.spyOn(MRWidgetService, 'fetchMetrics').mockResolvedValue({
        data: metricsMockData,
      });

      createComponent();
      await waitForPromises();

      expect(wrapper.classes()).toContain('mr-memory-usage');
      expect(findUsageInfo().exists()).toBe(true);
    });

    it('should show loading metrics message while metrics are being loaded', () => {
      createComponent();

      expect(findGlLoadingIcon().exists()).toBe(true);
      expect(findUsageInfo().exists()).toBe(true);
      expect(findUsageInfo().text()).toBe(messages.loadingMetrics);
    });

    it('should show deployment memory usage when metrics are loaded', async () => {
      jest.spyOn(MRWidgetService, 'fetchMetrics').mockResolvedValue({
        data: {
          ...metricsMockData,
          metrics: {
            ...metricsMockData.metrics,
            memory_after: [
              {
                metric: {},
                value: [0, '0'],
              },
            ],
            memory_before: [
              {
                metric: {},
                value: [0, '0'],
              },
            ],
          },
        },
      });

      createComponent();
      await waitForPromises();

      expect(findMemoryGraph().exists()).toBe(true);
      expect(findUsageInfo().text()).toBe(messages.hasMetrics);
    });

    it('should show failure message when metrics loading failed', async () => {
      jest.spyOn(MRWidgetService, 'fetchMetrics').mockRejectedValue({});

      createComponent();
      await waitForPromises();

      expect(findUsageInfoFailed().exists()).toBe(true);
      expect(findUsageInfo().text()).toBe(messages.loadFailed);
    });

    it('should show metrics unavailable message when metrics loading failed', async () => {
      jest.spyOn(MRWidgetService, 'fetchMetrics').mockResolvedValue({
        data: {
          ...metricsMockData,
          metrics: {
            ...metricsMockData.metrics,
            memory_values: [],
          },
        },
      });

      createComponent();
      await waitForPromises();

      expect(findUsageInfoUnavailable().exists()).toBe(true);
      expect(findUsageInfo().text()).toBe(messages.metricsUnavailable);
    });
  });
});
