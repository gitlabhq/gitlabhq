import $ from 'jquery';
import _ from 'underscore';
import PrometheusMetrics from '~/prometheus_metrics/prometheus_metrics';
import PANEL_STATE from '~/prometheus_metrics/constants';
import axios from '~/lib/utils/axios_utils';
import { s__ } from '~/locale';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';

export default class EEPrometheusMetrics extends PrometheusMetrics {
  constructor(wrapperSelector) {
    super(wrapperSelector);

    this.$wrapperCustomMetrics = $(wrapperSelector);
    this.$monitoredCustomMetricsPanel = this.$wrapperCustomMetrics.find('.js-panel-custom-monitored-metrics');
    this.$monitoredCustomMetricsCount = this.$monitoredCustomMetricsPanel.find('.js-custom-monitored-count');
    this.$monitoredCustomMetricsLoading = this.$monitoredCustomMetricsPanel.find('.js-loading-custom-metrics');
    this.$monitoredCustomMetricsEmpty = this.$monitoredCustomMetricsPanel.find('.js-empty-custom-metrics');
    this.$monitoredCustomMetricsList = this.$monitoredCustomMetricsPanel.find('.js-custom-metrics-list');
    this.$newCustomMetricButton = this.$monitoredCustomMetricsPanel.find('.js-new-metric-button');
    this.$flashCustomMetricsContainer = this.$wrapperCustomMetrics.find('.flash-container');
    this.customMetrics = [];
    this.environmentsData = [];

    this.activeCustomMetricsEndpoint = this.$monitoredCustomMetricsPanel.data('active-custom-metrics');
    this.environmentsDataEndpoint = this.$monitoredCustomMetricsPanel.data('environments-data-endpoint');
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
    const sortedMetrics = _(this.customMetrics).chain()
      .map(metric => ({ ...metric, group: capitalizeFirstCharacter(metric.group) }))
      .sortBy('title')
      .sortBy('group')
      .value();

    sortedMetrics.forEach((metric) => {
      this.$monitoredCustomMetricsList.append(EEPrometheusMetrics.customMetricTemplate(metric));
    });

    this.$monitoredCustomMetricsCount.text(this.customMetrics.length);
    this.showMonitoringCustomMetricsPanelState(PANEL_STATE.LIST);
    if (!this.environmentsData) {
      this.showFlashMessage(s__('PrometheusService|These metrics will only be monitored after your first deployment to an environment'));
    }
  }

  showFlashMessage(message) {
    this.$flashCustomMetricsContainer.removeClass('hidden');
    this.$flashCustomMetricsContainer.find('.flash-text').text(message);
  }

  loadActiveCustomMetrics() {
    super.loadActiveMetrics();
    Promise.all([
      axios.get(this.activeCustomMetricsEndpoint),
      axios.get(this.environmentsDataEndpoint),
    ])
      .then(([customMetrics, environmentsData]) => {
        this.environmentsData = environmentsData.data.environments;
        if (!customMetrics.data || !customMetrics.data.metrics) {
          this.showMonitoringCustomMetricsPanelState(PANEL_STATE.EMPTY);
        } else {
          this.customMetrics = customMetrics.data.metrics;
          this.populateCustomMetrics(customMetrics.data.metrics);
        }
      })
      .catch((customMetricError) => {
        this.showFlashMessage(customMetricError);
        this.showMonitoringCustomMetricsPanelState(PANEL_STATE.EMPTY);
      });
  }

  static customMetricTemplate(metric) {
    return `
    <li class="custom-metric">
      <a href="${_.escape(metric.edit_path)}" class="custom-metric-link-bold">
        ${_.escape(metric.group)} / ${_.escape(metric.title)} (${_.escape(metric.unit)})
      </a>
    </li>
  `;
  }
}
