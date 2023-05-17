import MockAdapter from 'axios-mock-adapter';
import prometheusIntegration from 'test_fixtures/integrations/prometheus/prometheus_integration.html';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import PANEL_STATE from '~/prometheus_metrics/constants';
import PrometheusMetrics from '~/prometheus_metrics/prometheus_metrics';
import { metrics2 as metrics, missingVarMetrics } from './mock_data';

describe('PrometheusMetrics', () => {
  beforeEach(() => {
    setHTMLFixture(prometheusIntegration);
  });

  describe('constructor', () => {
    let prometheusMetrics;

    beforeEach(() => {
      prometheusMetrics = new PrometheusMetrics('.js-prometheus-metrics-monitoring');
    });

    afterEach(() => {
      resetHTMLFixture();
    });

    it('should initialize wrapper element refs on class object', () => {
      expect(prometheusMetrics.$wrapper).toBeDefined();
      expect(prometheusMetrics.$monitoredMetricsPanel).toBeDefined();
      expect(prometheusMetrics.$monitoredMetricsCount).toBeDefined();
      expect(prometheusMetrics.$monitoredMetricsLoading).toBeDefined();
      expect(prometheusMetrics.$monitoredMetricsEmpty).toBeDefined();
      expect(prometheusMetrics.$monitoredMetricsList).toBeDefined();
      expect(prometheusMetrics.$missingEnvVarPanel).toBeDefined();
      expect(prometheusMetrics.$panelToggleRight).toBeDefined();
      expect(prometheusMetrics.$panelToggleDown).toBeDefined();
      expect(prometheusMetrics.$missingEnvVarMetricCount).toBeDefined();
      expect(prometheusMetrics.$missingEnvVarMetricsList).toBeDefined();
    });

    it('should initialize metadata on class object', () => {
      expect(prometheusMetrics.backOffRequestCounter).toEqual(0);
      expect(prometheusMetrics.activeMetricsEndpoint).toContain('/test');
    });
  });

  describe('showMonitoringMetricsPanelState', () => {
    let prometheusMetrics;

    beforeEach(() => {
      prometheusMetrics = new PrometheusMetrics('.js-prometheus-metrics-monitoring');
    });

    it('should show loading state when called with `loading`', () => {
      prometheusMetrics.showMonitoringMetricsPanelState(PANEL_STATE.LOADING);

      expect(prometheusMetrics.$monitoredMetricsLoading.hasClass('hidden')).toBe(false);
      expect(prometheusMetrics.$monitoredMetricsEmpty.hasClass('hidden')).toBe(true);
      expect(prometheusMetrics.$monitoredMetricsList.hasClass('hidden')).toBe(true);
    });

    it('should show metrics list when called with `list`', () => {
      prometheusMetrics.showMonitoringMetricsPanelState(PANEL_STATE.LIST);

      expect(prometheusMetrics.$monitoredMetricsLoading.hasClass('hidden')).toBe(true);
      expect(prometheusMetrics.$monitoredMetricsEmpty.hasClass('hidden')).toBe(true);
      expect(prometheusMetrics.$monitoredMetricsList.hasClass('hidden')).toBe(false);
    });

    it('should show empty state when called with `empty`', () => {
      prometheusMetrics.showMonitoringMetricsPanelState(PANEL_STATE.EMPTY);

      expect(prometheusMetrics.$monitoredMetricsLoading.hasClass('hidden')).toBe(true);
      expect(prometheusMetrics.$monitoredMetricsEmpty.hasClass('hidden')).toBe(false);
      expect(prometheusMetrics.$monitoredMetricsList.hasClass('hidden')).toBe(true);
    });
  });

  describe('populateActiveMetrics', () => {
    let prometheusMetrics;

    beforeEach(() => {
      prometheusMetrics = new PrometheusMetrics('.js-prometheus-metrics-monitoring');
    });

    it('should show monitored metrics list', () => {
      prometheusMetrics.populateActiveMetrics(metrics);

      const $metricsListLi = prometheusMetrics.$monitoredMetricsList.find('li');

      expect(prometheusMetrics.$monitoredMetricsLoading.hasClass('hidden')).toBe(true);
      expect(prometheusMetrics.$monitoredMetricsList.hasClass('hidden')).toBe(false);

      expect(prometheusMetrics.$monitoredMetricsCount.text()).toEqual(
        '3 exporters with 12 metrics were found',
      );

      expect($metricsListLi.length).toEqual(metrics.length);
      expect($metricsListLi.first().find('.badge').text()).toEqual(`${metrics[0].active_metrics}`);
    });

    it('should show missing environment variables list', () => {
      prometheusMetrics.populateActiveMetrics(missingVarMetrics);

      expect(prometheusMetrics.$monitoredMetricsLoading.hasClass('hidden')).toBe(true);
      expect(prometheusMetrics.$missingEnvVarPanel.hasClass('hidden')).toBe(false);

      expect(prometheusMetrics.$missingEnvVarMetricCount.text()).toEqual('2');
      expect(prometheusMetrics.$missingEnvVarPanel.find('li').length).toEqual(2);
      expect(prometheusMetrics.$missingEnvVarPanel.find('.flash-container')).toBeDefined();
    });
  });

  describe('loadActiveMetrics', () => {
    let prometheusMetrics;
    let mock;

    function mockSuccess() {
      mock.onGet(prometheusMetrics.activeMetricsEndpoint).reply(HTTP_STATUS_OK, {
        data: metrics,
        success: true,
      });
    }

    function mockError() {
      mock.onGet(prometheusMetrics.activeMetricsEndpoint).networkError();
    }

    beforeEach(() => {
      jest.spyOn(axios, 'get');

      prometheusMetrics = new PrometheusMetrics('.js-prometheus-metrics-monitoring');

      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    it('should show loader animation while response is being loaded and hide it when request is complete', async () => {
      mockSuccess();

      prometheusMetrics.loadActiveMetrics();

      expect(prometheusMetrics.$monitoredMetricsLoading.hasClass('hidden')).toBe(false);
      expect(axios.get).toHaveBeenCalledWith(prometheusMetrics.activeMetricsEndpoint);

      await waitForPromises();

      expect(prometheusMetrics.$monitoredMetricsLoading.hasClass('hidden')).toBe(true);
    });

    it('should show empty state if response failed to load', async () => {
      mockError();

      prometheusMetrics.loadActiveMetrics();

      await waitForPromises();

      expect(prometheusMetrics.$monitoredMetricsLoading.hasClass('hidden')).toBe(true);
      expect(prometheusMetrics.$monitoredMetricsEmpty.hasClass('hidden')).toBe(false);
    });

    it('should populate metrics list once response is loaded', async () => {
      jest.spyOn(prometheusMetrics, 'populateActiveMetrics').mockImplementation();
      mockSuccess();

      prometheusMetrics.loadActiveMetrics();

      await waitForPromises();

      expect(prometheusMetrics.populateActiveMetrics).toHaveBeenCalledWith(metrics);
    });
  });
});
