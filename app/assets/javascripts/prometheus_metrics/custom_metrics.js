import $ from 'jquery';
import { escape, sortBy } from 'lodash';
import axios from '~/lib/utils/axios_utils';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import { s__ } from '~/locale';
import PANEL_STATE from './constants';
import PrometheusMetrics from './prometheus_metrics';

export default class CustomMetrics extends PrometheusMetrics {
  constructor(wrapperSelector) {
    super(wrapperSelector);
    this.customMetrics = [];
    this.environmentsData = [];
    this.$els = [];

    this.$wrapperCustomMetrics = $(wrapperSelector);

    this.$monitoredCustomMetricsPanel = this.$wrapperCustomMetrics.find(
      '.js-panel-custom-monitored-metrics',
    );
    this.$monitoredCustomMetricsCount = this.$monitoredCustomMetricsPanel.find(
      '.js-custom-monitored-count',
    );
    this.$monitoredCustomMetricsLoading = this.$monitoredCustomMetricsPanel.find(
      '.js-loading-custom-metrics',
    );
    this.$monitoredCustomMetricsEmpty = this.$monitoredCustomMetricsPanel.find(
      '.js-empty-custom-metrics',
    );
    this.$monitoredCustomMetricsList = this.$monitoredCustomMetricsPanel.find(
      '.js-custom-metrics-list',
    );
    this.$monitoredCustomMetricsNoIntegrationText = this.$monitoredCustomMetricsPanel.find(
      '.js-no-active-integration-text',
    );
    this.$newCustomMetricButton = this.$monitoredCustomMetricsPanel.find('.js-new-metric-button');
    this.$newCustomMetricText = this.$monitoredCustomMetricsPanel.find('.js-new-metric-text');
    this.$flashCustomMetricsContainer = this.$wrapperCustomMetrics.find('.flash-container');

    this.$els = [
      this.$monitoredCustomMetricsLoading,
      this.$monitoredCustomMetricsList,
      this.$newCustomMetricButton,
      this.$newCustomMetricText,
      this.$monitoredCustomMetricsNoIntegrationText,
      this.$monitoredCustomMetricsEmpty,
    ];

    this.activeCustomMetricsEndpoint = this.$monitoredCustomMetricsPanel.data(
      'active-custom-metrics',
    );
    this.environmentsDataEndpoint = this.$monitoredCustomMetricsPanel.data(
      'environments-data-endpoint',
    );
    this.isServiceActive = this.$monitoredCustomMetricsPanel.data('service-active');
  }

  init() {
    if (this.isServiceActive) {
      this.loadActiveCustomMetrics();
    } else {
      this.setNoIntegrationActiveState();
    }
  }

  // eslint-disable-next-line class-methods-use-this
  setHidden(els) {
    els.forEach((el) => el.addClass('hidden'));
  }

  setVisible(...els) {
    this.setHidden(this.$els.filter((el) => !els.includes(el)));
    els.forEach((el) => el.removeClass('hidden'));
  }

  showMonitoringCustomMetricsPanelState(stateName) {
    switch (stateName) {
      case PANEL_STATE.LOADING:
        this.setVisible(this.$monitoredCustomMetricsLoading);
        break;
      case PANEL_STATE.LIST:
        this.setVisible(this.$newCustomMetricButton, this.$monitoredCustomMetricsList);
        break;
      case PANEL_STATE.NO_INTEGRATION:
        this.setVisible(
          this.$monitoredCustomMetricsNoIntegrationText,
          this.$monitoredCustomMetricsEmpty,
        );
        break;
      default:
        this.setVisible(
          this.$monitoredCustomMetricsEmpty,
          this.$newCustomMetricButton,
          this.$newCustomMetricText,
        );
        break;
    }
  }

  populateCustomMetrics() {
    const capitalizeGroup = (metric) => ({
      ...metric,
      group: capitalizeFirstCharacter(metric.group),
    });

    const sortedMetrics = sortBy(this.customMetrics.map(capitalizeGroup), ['group', 'title']);

    sortedMetrics.forEach((metric) => {
      this.$monitoredCustomMetricsList.append(CustomMetrics.customMetricTemplate(metric));
    });

    this.$monitoredCustomMetricsCount.text(this.customMetrics.length);
    this.showMonitoringCustomMetricsPanelState(PANEL_STATE.LIST);
    if (!this.environmentsData) {
      this.showFlashMessage(
        s__(
          'PrometheusService|These metrics will only be monitored after your first deployment to an environment',
        ),
      );
    }
  }

  showFlashMessage(message) {
    this.$flashCustomMetricsContainer.removeClass('hidden');
    this.$flashCustomMetricsContainer.find('.flash-text').text(message);
  }

  setNoIntegrationActiveState() {
    this.showMonitoringCustomMetricsPanelState(PANEL_STATE.NO_INTEGRATION);
    this.showMonitoringMetricsPanelState(PANEL_STATE.EMPTY);
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
      <a href="${escape(metric.edit_path)}" class="custom-metric-link-bold">
        ${escape(metric.group)} / ${escape(metric.title)} (${escape(metric.unit)})
      </a>
    </li>
  `;
  }
}
