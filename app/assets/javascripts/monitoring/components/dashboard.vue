<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import _ from 'underscore';
import { s__ } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import '~/vue_shared/mixins/is_ee';
import Flash from '../../flash';
import MonitoringService from '../services/monitoring_service';
import MonitorAreaChart from './charts/area.vue';
import GraphGroup from './graph_group.vue';
import EmptyState from './empty_state.vue';
import MonitoringStore from '../stores/monitoring_store';
import { timeWindows } from '../constants';
import { getTimeDiff } from '../utils';

const sidebarAnimationDuration = 150;
let sidebarMutationObserver;

export default {
  components: {
    MonitorAreaChart,
    GraphGroup,
    EmptyState,
    Icon,
    GlDropdown,
    GlDropdownItem,
  },

  props: {
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
    showTimeWindowDropdown: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      store: new MonitoringStore(),
      state: 'gettingStarted',
      showEmptyState: true,
      elWidth: 0,
      selectedTimeWindow: '',
    };
  },
  created() {
    this.service = new MonitoringService({
      metricsEndpoint: this.metricsEndpoint,
      deploymentEndpoint: this.deploymentEndpoint,
      environmentsEndpoint: this.environmentsEndpoint,
    });

    this.timeWindows = timeWindows;
    this.selectedTimeWindow = this.timeWindows.eightHours;
  },
  beforeDestroy() {
    if (sidebarMutationObserver) {
      sidebarMutationObserver.disconnect();
    }
  },
  mounted() {
    this.servicePromises = [
      this.service
        .getGraphsData()
        .then(data => this.store.storeMetrics(data))
        .catch(() => Flash(s__('Metrics|There was an error while retrieving metrics'))),
      this.service
        .getDeploymentData()
        .then(data => this.store.storeDeploymentData(data))
        .catch(() => Flash(s__('Metrics|There was an error getting deployment information.'))),
    ];
    if (!this.hasMetrics) {
      this.state = 'gettingStarted';
    } else {
      if (this.environmentsEndpoint) {
        this.servicePromises.push(
          this.service
            .getEnvironmentsData()
            .then(data => this.store.storeEnvironmentsData(data))
            .catch(() =>
              Flash(s__('Metrics|There was an error getting environments information.')),
            ),
        );
      }
      this.getGraphsData();
      sidebarMutationObserver = new MutationObserver(this.onSidebarMutation);
      sidebarMutationObserver.observe(document.querySelector('.layout-page'), {
        attributes: true,
        childList: false,
        subtree: false,
      });
    }
  },
  methods: {
    getGraphAlerts(queries) {
      if (!this.allAlerts) return {};
      const metricIdsForChart = queries.map(q => q.metricId);
      return _.pick(this.allAlerts, alert => metricIdsForChart.includes(alert.metricId));
    },
    getGraphAlertValues(queries) {
      return Object.values(this.getGraphAlerts(queries));
    },
    getGraphsData() {
      this.state = 'loading';
      Promise.all(this.servicePromises)
        .then(() => {
          if (this.store.groups.length < 1) {
            this.state = 'noData';
            return;
          }

          this.showEmptyState = false;
        })
        .catch(() => {
          this.state = 'unableToConnect';
        });
    },
    getGraphsDataWithTime(timeFrame) {
      this.state = 'loading';
      this.showEmptyState = true;
      this.service
        .getGraphsData(getTimeDiff(this.timeWindows[timeFrame]))
        .then(data => {
          this.store.storeMetrics(data);
          this.selectedTimeWindow = this.timeWindows[timeFrame];
        })
        .catch(() => {
          Flash(s__('Metrics|Not enough data to display'));
        })
        .finally(() => {
          this.showEmptyState = false;
        });
    },
    onSidebarMutation() {
      setTimeout(() => {
        this.elWidth = this.$el.clientWidth;
      }, sidebarAnimationDuration);
    },
    activeTimeWindow(key) {
      return this.timeWindows[key] === this.selectedTimeWindow;
    },
  },
};
</script>

<template>
  <div v-if="!showEmptyState" class="prometheus-graphs prepend-top-default">
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
          :disabled="store.environmentsData.length === 0"
        >
          <gl-dropdown-item
            v-for="environment in store.environmentsData"
            :key="environment.id"
            :href="environment.metrics_path"
            :active="environment.name === currentEnvironmentName"
            active-class="is-active"
            >{{ environment.name }}</gl-dropdown-item
          >
        </gl-dropdown>
      </div>
      <div v-if="showTimeWindowDropdown" class="d-flex align-items-center">
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
            @click="getGraphsDataWithTime(key)"
            >{{ value }}</gl-dropdown-item
          >
        </gl-dropdown>
      </div>
    </div>
    <graph-group
      v-for="(groupData, index) in store.groups"
      :key="index"
      :name="groupData.group"
      :show-panels="showPanels"
    >
      <monitor-area-chart
        v-for="(graphData, graphIndex) in groupData.metrics"
        :key="graphIndex"
        :graph-data="graphData"
        :deployment-data="store.deploymentData"
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
    :selected-state="state"
    :documentation-path="documentationPath"
    :settings-path="settingsPath"
    :clusters-path="clustersPath"
    :empty-getting-started-svg-path="emptyGettingStartedSvgPath"
    :empty-loading-svg-path="emptyLoadingSvgPath"
    :empty-no-data-svg-path="emptyNoDataSvgPath"
    :empty-unable-to-connect-svg-path="emptyUnableToConnectSvgPath"
  />
</template>
