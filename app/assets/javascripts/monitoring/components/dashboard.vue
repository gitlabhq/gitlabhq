<script>
// ee-only
import DashboardMixin from 'ee/monitoring/components/dashboard_mixin';

import _ from 'underscore';
import { s__ } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import Flash from '../../flash';
import MonitoringService from '../services/monitoring_service';
import GraphGroup from './graph_group.vue';
import Graph from './graph.vue';
import EmptyState from './empty_state.vue';
import MonitoringStore from '../stores/monitoring_store';
import eventHub from '../event_hub';

export default {
  components: {
    Graph,
    GraphGroup,
    EmptyState,
    Icon,
  },

  // ee-only
  mixins: [DashboardMixin],

  props: {
    hasMetrics: {
      type: Boolean,
      required: false,
      default: true,
    },
    showLegend: {
      type: Boolean,
      required: false,
      default: true,
    },
    showPanels: {
      type: Boolean,
      required: false,
      default: true,
    },
    forceSmallGraph: {
      type: Boolean,
      required: false,
      default: false,
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
  },
  data() {
    return {
      store: new MonitoringStore(),
      state: 'gettingStarted',
      showEmptyState: true,
      updateAspectRatio: false,
      updatedAspectRatios: 0,
      hoverData: {},
      resizeThrottled: {},
    };
  },
  created() {
    this.service = new MonitoringService({
      metricsEndpoint: this.metricsEndpoint,
      deploymentEndpoint: this.deploymentEndpoint,
      environmentsEndpoint: this.environmentsEndpoint,
    });
    eventHub.$on('toggleAspectRatio', this.toggleAspectRatio);
    eventHub.$on('hoverChanged', this.hoverChanged);
  },
  beforeDestroy() {
    eventHub.$off('toggleAspectRatio', this.toggleAspectRatio);
    eventHub.$off('hoverChanged', this.hoverChanged);
    window.removeEventListener('resize', this.resizeThrottled, false);
  },
  mounted() {
    this.resizeThrottled = _.throttle(this.resize, 600);
    if (!this.hasMetrics) {
      this.state = 'gettingStarted';
    } else {
      this.getGraphsData();
      window.addEventListener('resize', this.resizeThrottled, false);
    }
  },
  methods: {
    getGraphsData() {
      this.state = 'loading';
      Promise.all([
        this.service.getGraphsData().then(data => this.store.storeMetrics(data)),
        this.service
          .getDeploymentData()
          .then(data => this.store.storeDeploymentData(data))
          .catch(() => Flash(s__('Metrics|There was an error getting deployment information.'))),
        this.service
          .getEnvironmentsData()
          .then(data => this.store.storeEnvironmentsData(data))
          .catch(() => Flash(s__('Metrics|There was an error getting environments information.'))),
      ])
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
    resize() {
      this.updateAspectRatio = true;
    },
    toggleAspectRatio() {
      this.updatedAspectRatios += 1;
      if (this.store.getMetricsCount() === this.updatedAspectRatios) {
        this.updateAspectRatio = !this.updateAspectRatio;
        this.updatedAspectRatios = 0;
      }
    },
    hoverChanged(data) {
      this.hoverData = data;
    },
  },
};
</script>

<template>
  <div
    v-if="!showEmptyState"
    class="prometheus-graphs prepend-top-10"
  >
    <div class="environments d-flex align-items-center">
      {{ s__('Metrics|Environment') }}
      <div class="dropdown prepend-left-10">
        <button
          class="dropdown-menu-toggle"
          data-toggle="dropdown"
          type="button"
        >
          <span>
            {{ currentEnvironmentName }}
          </span>
          <icon
            name="chevron-down"
          />
        </button>
        <div class="dropdown-menu dropdown-menu-selectable dropdown-menu-drop-up">
          <ul>
            <li
              v-for="environment in store.environmentsData"
              :key="environment.latest.id"
            >
              <a
                :href="environment.latest.metrics_path"
                :class="{ 'is-active': environment.latest.name == currentEnvironmentName }"
                class="dropdown-item"
              >
                {{ environment.latest.name }}
              </a>
            </li>
          </ul>
        </div>
      </div>
    </div>
    <graph-group
      v-for="(groupData, index) in store.groups"
      :key="index"
      :name="groupData.group"
      :show-panels="showPanels"
    >
      <graph
        v-for="(graphData, index) in groupData.metrics"
        :key="index"
        :graph-data="graphData"
        :hover-data="hoverData"
        :update-aspect-ratio="updateAspectRatio"
        :deployment-data="store.deploymentData"
        :project-path="projectPath"
        :tags-path="tagsPath"
        :show-legend="showLegend"
        :small-graph="forceSmallGraph"
      >
        <!-- EE content -->
        <alert-widget
          v-if="alertsEndpoint && graphData.id"
          :alerts-endpoint="alertsEndpoint"
          :label="getGraphLabel(graphData)"
          :current-alerts="getQueryAlerts(graphData)"
          :custom-metric-id="graphData.id"
        />
      </graph>
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
