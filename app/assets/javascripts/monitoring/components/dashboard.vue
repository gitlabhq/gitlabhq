<script>
import {
  GlButton,
  GlDropdown,
  GlDropdownItem,
  GlModal,
  GlModalDirective,
  GlLink,
} from '@gitlab/ui';
import _ from 'underscore';
import { mapActions, mapState } from 'vuex';
import { s__ } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import '~/vue_shared/mixins/is_ee';
import { getParameterValues } from '~/lib/utils/url_utility';
import MonitorAreaChart from './charts/area.vue';
import GraphGroup from './graph_group.vue';
import EmptyState from './empty_state.vue';
import { timeWindows, timeWindowsKeyNames } from '../constants';
import { getTimeDiff } from '../utils';

const sidebarAnimationDuration = 150;
let sidebarMutationObserver;

export default {
  components: {
    MonitorAreaChart,
    GraphGroup,
    EmptyState,
    Icon,
    GlButton,
    GlDropdown,
    GlDropdownItem,
    GlLink,
    GlModal,
  },
  directives: {
    GlModalDirective,
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
    deploymentEndpoint: {
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
      required: true,
    },
    validateQueryPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      state: 'gettingStarted',
      elWidth: 0,
      selectedTimeWindow: '',
      selectedTimeWindowKey: '',
      formIsValid: null,
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
    ]),
  },
  created() {
    this.setEndpoints({
      metricsEndpoint: this.metricsEndpoint,
      environmentsEndpoint: this.environmentsEndpoint,
      deploymentsEndpoint: this.deploymentEndpoint,
    });

    this.timeWindows = timeWindows;
    this.selectedTimeWindowKey =
      _.escape(getParameterValues('time_window')[0]) || timeWindowsKeyNames.eightHours;

    // Set default time window if the selectedTimeWindowKey is bogus
    if (!Object.keys(this.timeWindows).includes(this.selectedTimeWindowKey)) {
      this.selectedTimeWindowKey = timeWindowsKeyNames.eightHours;
    }

    this.selectedTimeWindow = this.timeWindows[this.selectedTimeWindowKey];
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
      this.fetchData(getTimeDiff(this.selectedTimeWindow));

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
    ]),
    getGraphAlerts(queries) {
      if (!this.allAlerts) return {};
      const metricIdsForChart = queries.map(q => q.metricId);
      return _.pick(this.allAlerts, alert => metricIdsForChart.includes(alert.metricId));
    },
    getGraphAlertValues(queries) {
      return Object.values(this.getGraphAlerts(queries));
    },
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
      return `?time_window=${key}`;
    },
  },
  addMetric: {
    title: s__('Metrics|Add metric'),
    modalId: 'add-metric',
  },
};
</script>

<template>
  <div v-if="!showEmptyState" class="prometheus-graphs">
    <div class="gl-p-3 border-bottom bg-gray-light d-flex justify-content-between">
      <div
        v-if="environmentsEndpoint"
        class="dropdowns d-flex align-items-center justify-content-between"
      >
        <div class="d-flex align-items-center">
          <strong>{{ s__('Metrics|Environment') }}</strong>
          <gl-dropdown
            class="prepend-left-10 js-environments-dropdown"
            toggle-class="dropdown-menu-toggle"
            :text="currentEnvironmentName"
            :disabled="environments.length === 0"
          >
            <gl-dropdown-item
              v-for="environment in environments"
              :key="environment.id"
              :active="environment.name === currentEnvironmentName"
              active-class="is-active"
              >{{ environment.name }}</gl-dropdown-item
            >
          </gl-dropdown>
        </div>
        <div class="d-flex align-items-center prepend-left-8">
          <strong>{{ s__('Metrics|Show last') }}</strong>
          <gl-dropdown
            class="prepend-left-10 js-time-window-dropdown"
            toggle-class="dropdown-menu-toggle"
            :text="selectedTimeWindow"
          >
            <gl-dropdown-item
              v-for="(value, key) in timeWindows"
              :key="key"
              :active="activeTimeWindow(key)"
              ><gl-link :href="setTimeWindowParameter(key)">{{ value }}</gl-link></gl-dropdown-item
            >
          </gl-dropdown>
        </div>
      </div>
      <div class="d-flex">
        <div v-if="isEE && canAddMetrics">
          <gl-button
            v-gl-modal-directive="$options.addMetric.modalId"
            class="js-add-metric-button text-success border-success"
          >
            {{ $options.addMetric.title }}
          </gl-button>
          <gl-modal
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
              <gl-button @click="hideAddMetricModal">
                {{ __('Cancel') }}
              </gl-button>
              <gl-button
                :disabled="!formIsValid"
                variant="success"
                @click="submitCustomMetricsForm"
              >
                {{ __('Save changes') }}
              </gl-button>
            </div>
          </gl-modal>
        </div>
        <gl-button
          v-if="externalDashboardUrl.length"
          class="js-external-dashboard-link prepend-left-8"
          variant="primary"
          :href="externalDashboardUrl"
          target="_blank"
        >
          {{ __('View full dashboard') }}
          <icon name="external-link" />
        </gl-button>
      </div>
    </div>
    <graph-group
      v-for="(groupData, index) in groups"
      :key="index"
      :name="groupData.group"
      :show-panels="showPanels"
    >
      <monitor-area-chart
        v-for="(graphData, graphIndex) in groupData.metrics"
        :key="graphIndex"
        :graph-data="graphData"
        :deployment-data="deploymentData"
        :thresholds="getGraphAlertValues(graphData.queries)"
        :container-width="elWidth"
        group-id="monitor-area-chart"
      >
        <alert-widget
          v-if="isEE && prometheusAlertsAvailable && alertsEndpoint && graphData"
          :alerts-endpoint="alertsEndpoint"
          :relevant-queries="graphData.queries"
          :alerts-to-manage="getGraphAlerts(graphData.queries)"
          @setAlerts="setAlerts"
        />
      </monitor-area-chart>
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
  />
</template>
