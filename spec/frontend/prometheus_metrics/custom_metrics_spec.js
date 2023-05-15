import MockAdapter from 'axios-mock-adapter';
import prometheusIntegration from 'test_fixtures/integrations/prometheus/prometheus_integration.html';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import PANEL_STATE from '~/prometheus_metrics/constants';
import CustomMetrics from '~/prometheus_metrics/custom_metrics';
import { metrics1 as metrics } from './mock_data';

describe('PrometheusMetrics', () => {
  const customMetricsEndpoint =
    'http://test.host/frontend-fixtures/integrations-project/prometheus/metrics';
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onGet(customMetricsEndpoint).reply(HTTP_STATUS_OK, {
      metrics,
    });
    setHTMLFixture(prometheusIntegration);
  });

  afterEach(() => {
    mock.restore();
    resetHTMLFixture();
  });

  describe('Custom Metrics', () => {
    let customMetrics;

    beforeEach(() => {
      customMetrics = new CustomMetrics('.js-prometheus-metrics-monitoring');
    });

    it('should initialize wrapper element refs on the class object', () => {
      expect(customMetrics.$wrapperCustomMetrics).not.toBeNull();
      expect(customMetrics.$monitoredCustomMetricsPanel).not.toBeNull();
      expect(customMetrics.$monitoredCustomMetricsCount).not.toBeNull();
      expect(customMetrics.$monitoredCustomMetricsLoading).not.toBeNull();
      expect(customMetrics.$monitoredCustomMetricsEmpty).not.toBeNull();
      expect(customMetrics.$monitoredCustomMetricsList).not.toBeNull();
      expect(customMetrics.$newCustomMetricButton).not.toBeNull();
      expect(customMetrics.$flashCustomMetricsContainer).not.toBeNull();
    });

    it('should contain api endpoints', () => {
      expect(customMetrics.activeCustomMetricsEndpoint).toEqual(customMetricsEndpoint);
    });

    it('should show loading state when called with `loading`', () => {
      customMetrics.showMonitoringCustomMetricsPanelState(PANEL_STATE.LOADING);

      expect(customMetrics.$monitoredCustomMetricsLoading.hasClass('hidden')).toEqual(false);
      expect(customMetrics.$monitoredCustomMetricsEmpty.hasClass('hidden')).toBe(true);
      expect(customMetrics.$monitoredCustomMetricsList.hasClass('hidden')).toBe(true);
      expect(customMetrics.$monitoredCustomMetricsNoIntegrationText.hasClass('hidden')).toBe(true);

      expect(customMetrics.$newCustomMetricButton.hasClass('hidden')).toBe(true);
      expect(customMetrics.$newCustomMetricText.hasClass('hidden')).toBe(true);
    });

    it('should show metrics list when called with `list`', () => {
      customMetrics.showMonitoringCustomMetricsPanelState(PANEL_STATE.LIST);

      expect(customMetrics.$monitoredCustomMetricsLoading.hasClass('hidden')).toBe(true);
      expect(customMetrics.$monitoredCustomMetricsEmpty.hasClass('hidden')).toBe(true);
      expect(customMetrics.$monitoredCustomMetricsList.hasClass('hidden')).toEqual(false);
      expect(customMetrics.$monitoredCustomMetricsNoIntegrationText.hasClass('hidden')).toBe(true);

      expect(customMetrics.$newCustomMetricButton.hasClass('hidden')).toEqual(false);
      expect(customMetrics.$newCustomMetricText.hasClass('hidden')).toBe(true);
    });

    it('should show empty state when called with `empty`', () => {
      customMetrics.showMonitoringCustomMetricsPanelState(PANEL_STATE.EMPTY);

      expect(customMetrics.$monitoredCustomMetricsLoading.hasClass('hidden')).toBe(true);
      expect(customMetrics.$monitoredCustomMetricsEmpty.hasClass('hidden')).toEqual(false);
      expect(customMetrics.$monitoredCustomMetricsList.hasClass('hidden')).toBe(true);
      expect(customMetrics.$monitoredCustomMetricsNoIntegrationText.hasClass('hidden')).toBe(true);

      expect(customMetrics.$newCustomMetricButton.hasClass('hidden')).toEqual(false);
      expect(customMetrics.$newCustomMetricText.hasClass('hidden')).toEqual(false);
    });

    it('should show monitored metrics list', () => {
      customMetrics.customMetrics = metrics;
      customMetrics.populateCustomMetrics();

      const $metricsListLi = customMetrics.$monitoredCustomMetricsList.find('li');

      expect(customMetrics.$monitoredCustomMetricsLoading.hasClass('hidden')).toBe(true);
      expect(customMetrics.$monitoredCustomMetricsList.hasClass('hidden')).toEqual(false);
      expect(customMetrics.$monitoredCustomMetricsNoIntegrationText.hasClass('hidden')).toBe(true);

      expect(customMetrics.$newCustomMetricButton.hasClass('hidden')).toEqual(false);
      expect(customMetrics.$newCustomMetricText.hasClass('hidden')).toBe(true);

      expect($metricsListLi.length).toEqual(metrics.length);
    });

    it('should show the NO-INTEGRATION empty state', () => {
      customMetrics.setNoIntegrationActiveState();

      expect(customMetrics.$monitoredCustomMetricsEmpty.hasClass('hidden')).toEqual(false);
      expect(customMetrics.$monitoredCustomMetricsNoIntegrationText.hasClass('hidden')).toEqual(
        false,
      );

      expect(customMetrics.$monitoredCustomMetricsLoading.hasClass('hidden')).toBe(true);
      expect(customMetrics.$monitoredCustomMetricsList.hasClass('hidden')).toBe(true);
      expect(customMetrics.$newCustomMetricButton.hasClass('hidden')).toBe(true);
      expect(customMetrics.$newCustomMetricText.hasClass('hidden')).toBe(true);
    });
  });
});
