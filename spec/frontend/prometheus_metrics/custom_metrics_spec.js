import MockAdapter from 'axios-mock-adapter';
import PrometheusMetrics from '~/prometheus_metrics/custom_metrics';
import axios from '~/lib/utils/axios_utils';
import PANEL_STATE from '~/prometheus_metrics/constants';
import metrics from './mock_data';

describe('PrometheusMetrics', () => {
  const FIXTURE = 'services/prometheus/prometheus_service.html';
  const customMetricsEndpoint =
    'http://test.host/frontend-fixtures/services-project/prometheus/metrics';
  let mock;
  preloadFixtures(FIXTURE);

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onGet(customMetricsEndpoint).reply(200, {
      metrics,
    });
    loadFixtures(FIXTURE);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('Custom Metrics', () => {
    let prometheusMetrics;

    beforeEach(() => {
      prometheusMetrics = new PrometheusMetrics('.js-prometheus-metrics-monitoring');
    });

    it('should initialize wrapper element refs on the class object', () => {
      expect(prometheusMetrics.$wrapperCustomMetrics).not.toBeNull();
      expect(prometheusMetrics.$monitoredCustomMetricsPanel).not.toBeNull();
      expect(prometheusMetrics.$monitoredCustomMetricsCount).not.toBeNull();
      expect(prometheusMetrics.$monitoredCustomMetricsLoading).not.toBeNull();
      expect(prometheusMetrics.$monitoredCustomMetricsEmpty).not.toBeNull();
      expect(prometheusMetrics.$monitoredCustomMetricsList).not.toBeNull();
      expect(prometheusMetrics.$newCustomMetricButton).not.toBeNull();
      expect(prometheusMetrics.$flashCustomMetricsContainer).not.toBeNull();
    });

    it('should contain api endpoints', () => {
      expect(prometheusMetrics.activeCustomMetricsEndpoint).toEqual(customMetricsEndpoint);
    });

    it('should show loading state when called with `loading`', () => {
      prometheusMetrics.showMonitoringCustomMetricsPanelState(PANEL_STATE.LOADING);

      expect(prometheusMetrics.$monitoredCustomMetricsLoading.hasClass('hidden')).toEqual(false);
      expect(prometheusMetrics.$monitoredCustomMetricsEmpty.hasClass('hidden')).toBeTruthy();
      expect(prometheusMetrics.$monitoredCustomMetricsList.hasClass('hidden')).toBeTruthy();
      expect(
        prometheusMetrics.$monitoredCustomMetricsNoIntegrationText.hasClass('hidden'),
      ).toBeTruthy();

      expect(prometheusMetrics.$newCustomMetricButton.hasClass('hidden')).toBeTruthy();
      expect(prometheusMetrics.$newCustomMetricText.hasClass('hidden')).toBeTruthy();
    });

    it('should show metrics list when called with `list`', () => {
      prometheusMetrics.showMonitoringCustomMetricsPanelState(PANEL_STATE.LIST);

      expect(prometheusMetrics.$monitoredCustomMetricsLoading.hasClass('hidden')).toBeTruthy();
      expect(prometheusMetrics.$monitoredCustomMetricsEmpty.hasClass('hidden')).toBeTruthy();
      expect(prometheusMetrics.$monitoredCustomMetricsList.hasClass('hidden')).toEqual(false);
      expect(
        prometheusMetrics.$monitoredCustomMetricsNoIntegrationText.hasClass('hidden'),
      ).toBeTruthy();

      expect(prometheusMetrics.$newCustomMetricButton.hasClass('hidden')).toEqual(false);
      expect(prometheusMetrics.$newCustomMetricText.hasClass('hidden')).toBeTruthy();
    });

    it('should show empty state when called with `empty`', () => {
      prometheusMetrics.showMonitoringCustomMetricsPanelState(PANEL_STATE.EMPTY);

      expect(prometheusMetrics.$monitoredCustomMetricsLoading.hasClass('hidden')).toBeTruthy();
      expect(prometheusMetrics.$monitoredCustomMetricsEmpty.hasClass('hidden')).toEqual(false);
      expect(prometheusMetrics.$monitoredCustomMetricsList.hasClass('hidden')).toBeTruthy();
      expect(
        prometheusMetrics.$monitoredCustomMetricsNoIntegrationText.hasClass('hidden'),
      ).toBeTruthy();

      expect(prometheusMetrics.$newCustomMetricButton.hasClass('hidden')).toEqual(false);
      expect(prometheusMetrics.$newCustomMetricText.hasClass('hidden')).toEqual(false);
    });

    it('should show monitored metrics list', () => {
      prometheusMetrics.customMetrics = metrics;
      prometheusMetrics.populateCustomMetrics();

      const $metricsListLi = prometheusMetrics.$monitoredCustomMetricsList.find('li');

      expect(prometheusMetrics.$monitoredCustomMetricsLoading.hasClass('hidden')).toBeTruthy();
      expect(prometheusMetrics.$monitoredCustomMetricsList.hasClass('hidden')).toEqual(false);
      expect(
        prometheusMetrics.$monitoredCustomMetricsNoIntegrationText.hasClass('hidden'),
      ).toBeTruthy();

      expect(prometheusMetrics.$newCustomMetricButton.hasClass('hidden')).toEqual(false);
      expect(prometheusMetrics.$newCustomMetricText.hasClass('hidden')).toBeTruthy();

      expect($metricsListLi.length).toEqual(metrics.length);
    });

    it('should show the NO-INTEGRATION empty state', () => {
      prometheusMetrics.setNoIntegrationActiveState();

      expect(prometheusMetrics.$monitoredCustomMetricsEmpty.hasClass('hidden')).toEqual(false);
      expect(prometheusMetrics.$monitoredCustomMetricsNoIntegrationText.hasClass('hidden')).toEqual(
        false,
      );

      expect(prometheusMetrics.$monitoredCustomMetricsLoading.hasClass('hidden')).toBeTruthy();
      expect(prometheusMetrics.$monitoredCustomMetricsList.hasClass('hidden')).toBeTruthy();
      expect(prometheusMetrics.$newCustomMetricButton.hasClass('hidden')).toBeTruthy();
      expect(prometheusMetrics.$newCustomMetricText.hasClass('hidden')).toBeTruthy();
    });
  });
});
