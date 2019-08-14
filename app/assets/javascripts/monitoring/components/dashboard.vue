<script>
import {
  GlButton,
  GlDropdown,
  GlDropdownItem,
  GlFormGroup,
  GlModal,
  GlModalDirective,
  GlTooltipDirective,
} from '@gitlab/ui';
import _ from 'underscore';
import { mapActions, mapState } from 'vuex';
import { s__ } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import { getParameterValues } from '~/lib/utils/url_utility';
import invalidUrl from '~/lib/utils/invalid_url';
import MonitorAreaChart from './charts/area.vue';
import MonitorSingleStatChart from './charts/single_stat.vue';
import PanelType from './panel_type.vue';
import GraphGroup from './graph_group.vue';
import EmptyState from './empty_state.vue';
import { sidebarAnimationDuration, timeWindows } from '../constants';
import { getTimeDiff, getTimeWindow } from '../utils';

let sidebarMutationObserver;

export default {
  components: {
    MonitorAreaChart,
    MonitorSingleStatChart,
    PanelType,
    GraphGroup,
    EmptyState,
    Icon,
    GlButton,
    GlDropdown,
    GlDropdownItem,
    GlFormGroup,
    GlModal,
  },
  directives: {
    GlModal: GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  props: {
    externalDashboardUrl: {
      type: String,
      required: false,
      default: '',
    },
    hasMetrics: {
      type: Boolean,
      required: false,
      default: true,
    },
    showPanels: {
      type: Boolean,
      required: false,
      default: true,
    },
    documentationPath: {
      type: String,
      required: true,
    },
    settingsPath: {
      type: String,
      required: true,
    },
    clustersPath: {
      type: String,
      required: true,
    },
    tagsPath: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
    metricsEndpoint: {
      type: String,
      required: true,
    },
    deploymentsEndpoint: {
      type: String,
      required: false,
      default: null,
    },
    emptyGettingStartedSvgPath: {
      type: String,
      required: true,
    },
    emptyLoadingSvgPath: {
      type: String,
      required: true,
    },
    emptyNoDataSvgPath: {
      type: String,
      required: true,
    },
    emptyUnableToConnectSvgPath: {
      type: String,
      required: true,
    },
    environmentsEndpoint: {
      type: String,
      required: true,
    },
    currentEnvironmentName: {
      type: String,
      required: true,
    },
    customMetricsAvailable: {
      type: Boolean,
      required: false,
      default: false,
    },
    customMetricsPath: {
      type: String,
      required: false,
      default: invalidUrl,
    },
    validateQueryPath: {
      type: String,
      required: false,
      default: invalidUrl,
    },
    dashboardEndpoint: {
      type: String,
      required: false,
      default: invalidUrl,
    },
    currentDashboard: {
      type: String,
      required: false,
      default: '',
    },
    smallEmptyState: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      state: 'gettingStarted',
      elWidth: 0,
      selectedTimeWindow: '',
      selectedTimeWindowKey: '',
      formIsValid: null,
      timeWindows: {},
    };
  },
  computed: {
    canAddMetrics() {
      return this.customMetricsAvailable && this.customMetricsPath.length;
    },
    ...mapState('monitoringDashboard', [
      'groups',
      'emptyState',
      'showEmptyState',
      'environments',
      'deploymentData',
      'metricsWithData',
      'useDashboardEndpoint',
      'allDashboards',
      'multipleDashboardsEnabled',
      'additionalPanelTypesEnabled',
    ]),
    selectedDashboardText() {
      return this.currentDashboard || (this.allDashboards[0] && this.allDashboards[0].display_name);
    },
    addingMetricsAvailable() {
      return IS_EE && this.canAddMetrics && !this.showEmptyState;
    },
    alertWidgetAvailable() {
      return IS_EE && this.prometheusAlertsAvailable && this.alertsEndpoint;
    },
  },
  created() {
    this.setEndpoints({
      metricsEndpoint: this.metricsEndpoint,
      environmentsEndpoint: this.environmentsEndpoint,
      deploymentsEndpoint: this.deploymentsEndpoint,
      dashboardEndpoint: this.dashboardEndpoint,
      currentDashboard: this.currentDashboard,
      projectPath: this.projectPath,
    });
  },
  beforeDestroy() {
    if (sidebarMutationObserver) {
      sidebarMutationObserver.disconnect();
    }
  },
  mounted() {
    if (!this.hasMetrics) {
      this.setGettingStartedEmptyState();
    } else {
      const defaultRange = getTimeDiff();
      const start = getParameterValues('start')[0] || defaultRange.start;
      const end = getParameterValues('end')[0] || defaultRange.end;

      const range = {
        start,
        end,
      };

      this.timeWindows = timeWindows;
      this.selectedTimeWindowKey = getTimeWindow(range);
      this.selectedTimeWindow = this.timeWindows[this.selectedTimeWindowKey];

      this.fetchData(range);

      sidebarMutationObserver = new MutationObserver(this.onSidebarMutation);
      sidebarMutationObserver.observe(document.querySelector('.layout-page'), {
        attributes: true,
        childList: false,
        subtree: false,
      });
    }
  },
  methods: {
    ...mapActions('monitoringDashboard', [
      'fetchData',
      'setGettingStartedEmptyState',
      'setEndpoints',
      'setDashboardEnabled',
    ]),
    chartsWithData(charts) {
      if (!this.useDashboardEndpoint) {
        return charts;
      }
      return charts.filter(chart =>
        chart.metrics.some(metric => this.metricsWithData.includes(metric.metric_id)),
      );
    },
    csvText(graphData) {
      const chartData = graphData.queries[0].result[0].values;
      const yLabel = graphData.y_label;
      const header = `timestamp,${yLabel}\r\n`; // eslint-disable-line @gitlab/i18n/no-non-i18n-strings
      return chartData.reduce((csv, data) => {
        const row = data.join(',');
        return `${csv}${row}\r\n`;
      }, header);
    },
    downloadCsv(graphData) {
      const data = new Blob([this.csvText(graphData)], { type: 'text/plain' });
      return window.URL.createObjectURL(data);
    },
    // TODO: BEGIN, Duplicated code with panel_type until feature flag is removed
    // Issue number: https://gitlab.com/gitlab-org/gitlab-ce/issues/63845
    getGraphAlerts(queries) {
      if (!this.allAlerts) return {};
      const metricIdsForChart = queries.map(q => q.metricId);
      return _.pick(this.allAlerts, alert => metricIdsForChart.includes(alert.metricId));
    },
    getGraphAlertValues(queries) {
      return Object.values(this.getGraphAlerts(queries));
    },
    // TODO: END
    hideAddMetricModal() {
      this.$refs.addMetricModal.hide();
    },
    onSidebarMutation() {
      setTimeout(() => {
        this.elWidth = this.$el.clientWidth;
      }, sidebarAnimationDuration);
    },
    setFormValidity(isValid) {
      this.formIsValid = isValid;
    },
    submitCustomMetricsForm() {
      this.$refs.customMetricsForm.submit();
    },
    activeTimeWindow(key) {
      return this.timeWindows[key] === this.selectedTimeWindow;
    },
    setTimeWindowParameter(key) {
      const { start, end } = getTimeDiff(key);
      return `?start=${encodeURIComponent(start)}&end=${encodeURIComponent(end)}`;
    },
    groupHasData(group) {
      return this.chartsWithData(group.metrics).length > 0;
    },
  },
  addMetric: {
    title: s__('Metrics|Add metric'),
    modalId: 'add-metric',
  },
};
</script>

<template>
  <div class="prometheus-graphs">
    <div class="gl-p-3 pb-0 border-bottom bg-gray-light">
      <div class="row">
        <template v-if="environmentsEndpoint">
          <gl-form-group
            v-if="multipleDashboardsEnabled"
            :label="__('Dashboard')"
            label-size="sm"
            label-for="monitor-dashboards-dropdown"
            class="col-sm-12 col-md-4 col-lg-2"
          >
            <gl-dropdown
              id="monitor-dashboards-dropdown"
              class="mb-0 d-flex js-dashboards-dropdown"
              toggle-class="dropdown-menu-toggle"
              :text="selectedDashboardText"
            >
              <gl-dropdown-item
                v-for="dashboard in allDashboards"
                :key="dashboard.path"
                :active="dashboard.path === currentDashboard"
                active-class="is-active"
                :href="`?dashboard=${dashboard.path}`"
                >{{ dashboard.display_name || dashboard.path }}</gl-dropdown-item
              >
            </gl-dropdown>
          </gl-form-group>

          <gl-form-group
            :label="s__('Metrics|Environment')"
            label-size="sm"
            label-for="monitor-environments-dropdown"
            class="col-sm-6 col-md-4 col-lg-2"
          >
            <gl-dropdown
              id="monitor-environments-dropdown"
              class="mb-0 d-flex js-environments-dropdown"
              toggle-class="dropdown-menu-toggle"
              :text="currentEnvironmentName"
              :disabled="environments.length === 0"
            >
              <gl-dropdown-item
                v-for="environment in environments"
                :key="environment.id"
                :active="environment.name === currentEnvironmentName"
                active-class="is-active"
                :href="environment.metrics_path"
                >{{ environment.name }}</gl-dropdown-item
              >
            </gl-dropdown>
          </gl-form-group>

          <gl-form-group
            v-if="!showEmptyState"
            :label="s__('Metrics|Show last')"
            label-size="sm"
            label-for="monitor-time-window-dropdown"
            class="col-sm-6 col-md-4 col-lg-2"
          >
            <gl-dropdown
              id="monitor-time-window-dropdown"
              class="mb-0 d-flex js-time-window-dropdown"
              toggle-class="dropdown-menu-toggle"
              :text="selectedTimeWindow"
            >
              <gl-dropdown-item
                v-for="(value, key) in timeWindows"
                :key="key"
                :active="activeTimeWindow(key)"
                :href="setTimeWindowParameter(key)"
                active-class="active"
                >{{ value }}</gl-dropdown-item
              >
            </gl-dropdown>
          </gl-form-group>
        </template>

        <gl-form-group
          v-if="addingMetricsAvailable || externalDashboardUrl.length"
          label-for="prometheus-graphs-dropdown-buttons"
          class="dropdown-buttons col-lg d-lg-flex align-items-end"
        >
          <div id="prometheus-graphs-dropdown-buttons">
            <gl-button
              v-if="addingMetricsAvailable"
              v-gl-modal="$options.addMetric.modalId"
              class="mr-2 mt-1 js-add-metric-button text-success border-success"
            >
              {{ $options.addMetric.title }}
            </gl-button>
            <gl-modal
              v-if="addingMetricsAvailable"
              ref="addMetricModal"
              :modal-id="$options.addMetric.modalId"
              :title="$options.addMetric.title"
            >
              <form ref="customMetricsForm" :action="customMetricsPath" method="post">
                <custom-metrics-form-fields
                  :validate-query-path="validateQueryPath"
                  form-operation="post"
                  @formValidation="setFormValidity"
                />
              </form>
              <div slot="modal-footer">
                <gl-button @click="hideAddMetricModal">{{ __('Cancel') }}</gl-button>
                <gl-button
                  :disabled="!formIsValid"
                  variant="success"
                  @click="submitCustomMetricsForm"
                >
                  {{ __('Save changes') }}
                </gl-button>
              </div>
            </gl-modal>

            <gl-button
              v-if="externalDashboardUrl.length"
              class="mt-1 js-external-dashboard-link"
              variant="primary"
              :href="externalDashboardUrl"
              target="_blank"
              rel="noopener noreferrer"
            >
              {{ __('View full dashboard') }}
              <icon name="external-link" />
            </gl-button>
          </div>
        </gl-form-group>
      </div>
    </div>

    <div v-if="!showEmptyState">
      <graph-group
        v-for="(groupData, index) in groups"
        :key="`${groupData.group}.${groupData.priority}`"
        :name="groupData.group"
        :show-panels="showPanels"
        :collapse-group="groupHasData(groupData)"
      >
        <template v-if="additionalPanelTypesEnabled">
          <panel-type
            v-for="(graphData, graphIndex) in groupData.metrics"
            :key="`panel-type-${graphIndex}`"
            :graph-data="graphData"
            :dashboard-width="elWidth"
            :index="`${index}-${graphIndex}`"
          />
        </template>
        <template v-else>
          <monitor-area-chart
            v-for="(graphData, graphIndex) in chartsWithData(groupData.metrics)"
            :key="graphIndex"
            :graph-data="graphData"
            :deployment-data="deploymentData"
            :thresholds="getGraphAlertValues(graphData.queries)"
            :container-width="elWidth"
            :project-path="projectPath"
            group-id="monitor-area-chart"
          >
            <div class="d-flex align-items-center">
              <alert-widget
                v-if="alertWidgetAvailable && graphData"
                :modal-id="`alert-modal-${index}-${graphIndex}`"
                :alerts-endpoint="alertsEndpoint"
                :relevant-queries="graphData.queries"
                :alerts-to-manage="getGraphAlerts(graphData.queries)"
                @setAlerts="setAlerts"
              />
              <gl-dropdown
                v-gl-tooltip
                class="mx-2"
                toggle-class="btn btn-transparent border-0"
                :right="true"
                :no-caret="true"
                :title="__('More actions')"
              >
                <template slot="button-content">
                  <icon name="ellipsis_v" class="text-secondary" />
                </template>
                <gl-dropdown-item :href="downloadCsv(graphData)" download="chart_metrics.csv">
                  {{ __('Download CSV') }}
                </gl-dropdown-item>
                <gl-dropdown-item
                  v-if="alertWidgetAvailable"
                  v-gl-modal="`alert-modal-${index}-${graphIndex}`"
                >
                  {{ __('Alerts') }}
                </gl-dropdown-item>
              </gl-dropdown>
            </div>
          </monitor-area-chart>
        </template>
      </graph-group>
    </div>
    <empty-state
      v-else
      :selected-state="emptyState"
      :documentation-path="documentationPath"
      :settings-path="settingsPath"
      :clusters-path="clustersPath"
      :empty-getting-started-svg-path="emptyGettingStartedSvgPath"
      :empty-loading-svg-path="emptyLoadingSvgPath"
      :empty-no-data-svg-path="emptyNoDataSvgPath"
      :empty-unable-to-connect-svg-path="emptyUnableToConnectSvgPath"
      :compact="smallEmptyState"
    />
  </div>
</template>
