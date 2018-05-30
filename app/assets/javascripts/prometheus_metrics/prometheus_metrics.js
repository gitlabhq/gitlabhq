import $ from 'jquery';
import _ from 'underscore';
import { s__, n__, sprintf } from '~/locale';
import axios from '../lib/utils/axios_utils';
import PANEL_STATE from './constants';
import { backOff } from '../lib/utils/common_utils';

export default class PrometheusMetrics {
  constructor(wrapperSelector) {
    this.backOffRequestCounter = 0;

    this.$wrapper = $(wrapperSelector);

    this.$monitoredMetricsPanel = this.$wrapper.find('.js-panel-monitored-metrics');
    this.$monitoredMetricsCount = this.$monitoredMetricsPanel.find('.js-monitored-count');
    this.$monitoredMetricsLoading = this.$monitoredMetricsPanel.find('.js-loading-metrics');
    this.$monitoredMetricsEmpty = this.$monitoredMetricsPanel.find('.js-empty-metrics');
    this.$monitoredMetricsList = this.$monitoredMetricsPanel.find('.js-metrics-list');

    this.$missingEnvVarPanel = this.$wrapper.find('.js-panel-missing-env-vars');
    this.$panelToggle = this.$missingEnvVarPanel.find('.js-panel-toggle');
    this.$missingEnvVarMetricCount = this.$missingEnvVarPanel.find('.js-env-var-count');
    this.$missingEnvVarMetricsList = this.$missingEnvVarPanel.find('.js-missing-var-metrics-list');

    this.activeMetricsEndpoint = this.$monitoredMetricsPanel.data('activeMetrics');
    this.helpMetricsPath = this.$monitoredMetricsPanel.data('metrics-help-path');

    this.$panelToggle.on('click', e => this.handlePanelToggle(e));
  }

  /* eslint-disable class-methods-use-this */
  handlePanelToggle(e) {
    const $toggleBtn = $(e.currentTarget);
    const $currentPanelBody = $toggleBtn.closest('.card').find('.card-body');
    $currentPanelBody.toggleClass('hidden');
    if ($toggleBtn.hasClass('fa-caret-down')) {
      $toggleBtn.removeClass('fa-caret-down').addClass('fa-caret-right');
    } else {
      $toggleBtn.removeClass('fa-caret-right').addClass('fa-caret-down');
    }
  }

  showMonitoringMetricsPanelState(stateName) {
    switch (stateName) {
      case PANEL_STATE.LOADING:
        this.$monitoredMetricsLoading.removeClass('hidden');
        this.$monitoredMetricsEmpty.addClass('hidden');
        this.$monitoredMetricsList.addClass('hidden');
        break;
      case PANEL_STATE.LIST:
        this.$monitoredMetricsLoading.addClass('hidden');
        this.$monitoredMetricsEmpty.addClass('hidden');
        this.$monitoredMetricsList.removeClass('hidden');
        break;
      default:
        this.$monitoredMetricsLoading.addClass('hidden');
        this.$monitoredMetricsEmpty.removeClass('hidden');
        this.$monitoredMetricsList.addClass('hidden');
        break;
    }
  }

  populateActiveMetrics(metrics) {
    let totalMonitoredMetrics = 0;
    let totalMissingEnvVarMetrics = 0;
    let totalExporters = 0;

    metrics.forEach((metric) => {
      if (metric.active_metrics > 0) {
        totalExporters += 1;
        this.$monitoredMetricsList.append(`<li>${_.escape(metric.group)}<span class="badge">${_.escape(metric.active_metrics)}</span></li>`);
        totalMonitoredMetrics += metric.active_metrics;
        if (metric.metrics_missing_requirements > 0) {
          this.$missingEnvVarMetricsList.append(`<li>${_.escape(metric.group)}</li>`);
          totalMissingEnvVarMetrics += 1;
        }
      }
    });

    if (totalMonitoredMetrics === 0) {
      const emptyCommonMetricsText = sprintf(s__('PrometheusService|<p class="text-tertiary">No <a href="%{docsUrl}">common metrics</a> were found</p>'), {
        docsUrl: this.helpMetricsPath,
      }, false);
      this.$monitoredMetricsEmpty.empty();
      this.$monitoredMetricsEmpty.append(emptyCommonMetricsText);
      this.showMonitoringMetricsPanelState(PANEL_STATE.EMPTY);
    } else {
      const metricsCountText = sprintf(s__('PrometheusService|%{exporters} with %{metrics} were found'), {
        exporters: n__('%d exporter', '%d exporters', totalExporters),
        metrics: n__('%d metric', '%d metrics', totalMonitoredMetrics),
      });
      this.$monitoredMetricsCount.text(metricsCountText);
      this.showMonitoringMetricsPanelState(PANEL_STATE.LIST);

      if (totalMissingEnvVarMetrics > 0) {
        this.$missingEnvVarPanel.removeClass('hidden');
        this.$missingEnvVarMetricCount.text(totalMissingEnvVarMetrics);
      }
    }
  }

  loadActiveMetrics() {
    this.showMonitoringMetricsPanelState(PANEL_STATE.LOADING);
    backOff((next, stop) => {
      axios.get(this.activeMetricsEndpoint)
        .then(({ data }) => {
          if (data && data.success) {
            stop(data);
          } else {
            this.backOffRequestCounter = this.backOffRequestCounter += 1;
            if (this.backOffRequestCounter < 3) {
              next();
            } else {
              stop(data);
            }
          }
        })
        .catch(stop);
    })
      .then((res) => {
        if (res && res.data && res.data.length) {
          this.populateActiveMetrics(res.data);
        } else {
          this.showMonitoringMetricsPanelState(PANEL_STATE.EMPTY);
        }
      })
      .catch(() => {
        this.showMonitoringMetricsPanelState(PANEL_STATE.EMPTY);
      });
  }
}
