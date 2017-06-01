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

    this.activeMetricsEndpoint = this.$monitoredMetricsPanel.data('active-metrics');
  }

  init() {
    this.$panelToggle.on('click', e => this.handlePanelToggle(e));
  }

  /* eslint-disable class-methods-use-this */
  handlePanelToggle(e) {
    const $toggleBtn = $(e.currentTarget);
    const $currentPanelBody = $toggleBtn.parents('.panel').find('.panel-body');
    if ($currentPanelBody.is(':visible')) {
      $currentPanelBody.addClass('hidden');
      $toggleBtn.removeClass('fa-caret-down').addClass('fa-caret-right');
    } else {
      $currentPanelBody.removeClass('hidden');
      $toggleBtn.removeClass('fa-caret-right').addClass('fa-caret-down');
    }
  }

  populateActiveMetrics(metrics) {
    let totalMonitoredMetrics = 0;
    let totalMissingEnvVarMetrics = 0;

    metrics.forEach((metric) => {
      this.$monitoredMetricsList.append(`<li>${metric.group}<span class="badge-count">${metric.active_metrics}</span></li>`);
      totalMonitoredMetrics += metric.active_metrics;
      if (metric.metrics_missing_requirements > 0) {
        this.$missingEnvVarMetricsList.append(`<li>${metric.group}</li>`);
        totalMissingEnvVarMetrics += 1;
      }
    });

    this.$monitoredMetricsCount.text(totalMonitoredMetrics);
    this.$monitoredMetricsLoading.addClass('hidden');
    this.$monitoredMetricsList.removeClass('hidden');

    if (totalMissingEnvVarMetrics > 0) {
      this.$missingEnvVarPanel.removeClass('hidden');
      this.$missingEnvVarMetricCount.text(totalMissingEnvVarMetrics);
    }
  }

  loadActiveMetrics() {
    this.$monitoredMetricsLoading.removeClass('hidden');
    gl.utils.backOff((next, stop) => {
      $.getJSON(this.activeMetricsEndpoint)
        .done((res) => {
          if (res && res.success) {
            stop(res);
          } else {
            this.backOffRequestCounter = this.backOffRequestCounter += 1;
            if (this.backOffRequestCounter < 3) {
              next();
            } else {
              stop(res);
            }
          }
        })
        .fail(stop);
    })
    .then((res) => {
      if (res && res.data && res.data.length) {
        this.populateActiveMetrics(res.data);
      } else {
        this.$monitoredMetricsLoading.addClass('hidden');
        this.$monitoredMetricsEmpty.removeClass('hidden');
      }
    })
    .catch(() => {
      this.$monitoredMetricsLoading.addClass('hidden');
      this.$monitoredMetricsEmpty.removeClass('hidden');
    });
  }
}
