import CEPrometheusMetrics from '~/prometheus_metrics/prometheus_metrics';
import PANEL_STATE from '~/prometheus_metrics/constants';
import axios from '~/lib/utils/axios_utils';
import statusCodes from '~/lib/utils/http_status';
import { backOff } from '~/lib/utils/common_utils';

const MAX_REQUESTS = 3;

function backOffRequest(makeRequestCallback) {
  let requestCounter = 0;
  return backOff((next, stop) => {
    makeRequestCallback().then((resp) => {
      if (resp.status === statusCodes.NO_CONTENT) {
        requestCounter += 1;
        if (requestCounter < MAX_REQUESTS) {
          next();
        } else {
          stop(new Error('Failed to retrieve prometheus custom metrics'));
        }
      } else {
        stop(resp);
      }
    }).catch(stop);
  });
}

export default class PrometheusMetrics {
  constructor(wrapperSelector) {
    // Call the common metrics (CE stuff basically)
    const cePrometheusMetrics = new CEPrometheusMetrics(wrapperSelector);
    cePrometheusMetrics.loadActiveMetrics();

    this.$wrapperCustomMetrics = $(wrapperSelector);
    this.$monitoredCustomMetricsPanel = this.$wrapperCustomMetrics.find('.js-panel-custom-monitored-metrics');
    this.$monitoredCustomMetricsCount = this.$monitoredCustomMetricsPanel.find('.js-custom-monitored-count');
    this.$monitoredCustomMetricsLoading = this.$monitoredCustomMetricsPanel.find('.js-loading-custom-metrics');
    this.$monitoredCustomMetricsEmpty = this.$monitoredCustomMetricsPanel.find('.js-empty-custom-metrics');
    this.$monitoredCustomMetricsList = this.$monitoredCustomMetricsPanel.find('.js-custom-metrics-list');

    this.activeCustomMetricsEndpoint = this.$monitoredCustomMetricsPanel.data('active-custom-metrics');
  }

  showMonitoringCustomMetricsPanelState(stateName) {
    switch (stateName) {
      case PANEL_STATE.LOADING:
        this.$monitoredCustomMetricsLoading.removeClass('hidden');
        this.$monitoredCustomMetricsEmpty.addClass('hidden');
        this.$monitoredCustomMetricsList.addClass('hidden');
        break;
      case PANEL_STATE.LIST:
        this.$monitoredCustomMetricsLoading.addClass('hidden');
        this.$monitoredCustomMetricsEmpty.addClass('hidden');
        this.$monitoredCustomMetricsList.removeClass('hidden');
        break;
      default:
        this.$monitoredCustomMetricsLoading.addClass('hidden');
        this.$monitoredCustomMetricsEmpty.removeClass('hidden');
        this.$monitoredCustomMetricsList.addClass('hidden');
        break;
    }
  }

  populateActiveMetrics(metrics) {
    let totalMonitoredMetrics = 0;

    metrics.forEach((metric) => {
      this.$monitoredMetricsList.append(`<li>${metric.group}</li>`);
      totalMonitoredMetrics += metric.active_metrics;
    });

    this.$monitoredMetricsCount.text(totalMonitoredMetrics);
    this.showMonitoringCustomMetricsPanelState(PANEL_STATE.LIST);
  }

  loadActiveCustomMetrics() {
    backOffRequest(() => axios.get(this.activeCustomMetricsEndpoint))
    .then(resp => resp.data)
    .then((response) => {
      if (!response || !response.data) {
        // add a flash
        this.showMonitoringCustomMetricsPanelState(PANEL_STATE.EMPTY);
      } else {
        this.populateActiveMetrics(response.data);
      }
    }).catch((err) => {
      this.showMonitoringCustomMetricsPanelState(PANEL_STATE.EMPTY);
    });
  }
}
