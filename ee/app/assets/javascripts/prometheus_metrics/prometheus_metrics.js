import _ from 'underscore';
import CEPrometheusMetrics from '~/prometheus_metrics/prometheus_metrics';
import PANEL_STATE from '~/prometheus_metrics/constants';
import axios from '~/lib/utils/axios_utils';
import statusCodes from '~/lib/utils/http_status';
import { backOff, spriteIcon } from '~/lib/utils/common_utils';

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

function customMetricTemplate(metric) {
  const deleteIcon = spriteIcon('file-deletion');
  return `
      <li class="custom-metric">
        <a
          href="${metric.edit_path}">
          ${metric.title}
        </a>
        <a
          href="#"
          class="delete-custom-metric"
          data-metric-id="${metric.id}">
          ${deleteIcon}
        </a>
      </li>
    `;
}

export default class PrometheusMetrics {
  constructor(wrapperSelector) {
    const cePrometheusMetrics = new CEPrometheusMetrics(wrapperSelector);
    cePrometheusMetrics.loadActiveMetrics();

    this.$wrapperCustomMetrics = $(wrapperSelector);
    this.$monitoredCustomMetricsPanel = this.$wrapperCustomMetrics.find('.js-panel-custom-monitored-metrics');
    this.$monitoredCustomMetricsCount = this.$monitoredCustomMetricsPanel.find('.js-custom-monitored-count');
    this.$monitoredCustomMetricsLoading = this.$monitoredCustomMetricsPanel.find('.js-loading-custom-metrics');
    this.$monitoredCustomMetricsEmpty = this.$monitoredCustomMetricsPanel.find('.js-empty-custom-metrics');
    this.$monitoredCustomMetricsList = this.$monitoredCustomMetricsPanel.find('.js-custom-metrics-list');
    this.$newCustomMetricButton = this.$monitoredCustomMetricsPanel.find('.js-new-metric-button');
    this.$flashCustomMetricsContainer = this.$wrapperCustomMetrics.find('.flash-container');
    this.customMetrics = [];

    this.activeCustomMetricsEndpoint = this.$monitoredCustomMetricsPanel.data('active-custom-metrics');
    this.customMetricsEndpoint = this.activeCustomMetricsEndpoint.replace('.json', '/');
  }

  deleteMetricEndpoint(id) {
    return `${this.customMetricsEndpoint}${id}`;
  }

  deleteMetric(currentTarget) {
    const targetId = currentTarget.dataset.metricId;
    axios.delete(this.deleteMetricEndpoint(targetId))
    .then(() => {
      currentTarget.parentElement.remove();
      const elementToFind = { id: parseInt(targetId, 10) };
      const indexToDelete = _.findLastIndex(this.customMetrics, elementToFind);
      this.customMetrics.splice(indexToDelete, 1);
      this.$monitoredCustomMetricsCount.text(this.customMetrics.length);
      if (this.customMetrics.length === 0) {
        this.showMonitoringCustomMetricsPanelState(PANEL_STATE.EMPTY);
      }
    })
    .catch((err) => {
      this.showFlashMessage(err);
    });
  }

  showMonitoringCustomMetricsPanelState(stateName) {
    switch (stateName) {
      case PANEL_STATE.LOADING:
        this.$monitoredCustomMetricsLoading.removeClass('hidden');
        this.$monitoredCustomMetricsEmpty.addClass('hidden');
        this.$monitoredCustomMetricsList.addClass('hidden');
        this.$newCustomMetricButton.addClass('hidden');
        break;
      case PANEL_STATE.LIST:
        this.$monitoredCustomMetricsLoading.addClass('hidden');
        this.$monitoredCustomMetricsEmpty.addClass('hidden');
        this.$newCustomMetricButton.removeClass('hidden');
        this.$monitoredCustomMetricsList.removeClass('hidden');
        break;
      default:
        this.$monitoredCustomMetricsLoading.addClass('hidden');
        this.$monitoredCustomMetricsEmpty.removeClass('hidden');
        this.$monitoredCustomMetricsList.addClass('hidden');
        this.$newCustomMetricButton.addClass('hidden');
        break;
    }
  }

  populateCustomMetrics() {
    this.customMetrics.forEach((metric) => {
      this.$monitoredCustomMetricsList.append(customMetricTemplate(metric));
    });

    this.$monitoredCustomMetricsCount.text(this.customMetrics.length);
    this.showMonitoringCustomMetricsPanelState(PANEL_STATE.LIST);
    this.$monitoredCustomMetricsList.find('.delete-custom-metric').on('click', (event) => {
      this.deleteMetric(event.currentTarget);
    });
  }

  showFlashMessage(message) {
    this.$flashCustomMetricsContainer.removeClass('hidden');
    this.$flashCustomMetricsContainer.find('.flash-text').text(message);
  }

  loadActiveCustomMetrics() {
    backOffRequest(() => axios.get(this.activeCustomMetricsEndpoint))
    .then(resp => resp.data)
    .then((response) => {
      if (!response || !response.metrics) {
        this.showMonitoringCustomMetricsPanelState(PANEL_STATE.EMPTY);
      } else {
        this.customMetrics = response.metrics;
        this.populateCustomMetrics(response.metrics);
      }
    }).catch(() => {
      this.showMonitoringCustomMetricsPanelState(PANEL_STATE.EMPTY);
    });
  }
}
