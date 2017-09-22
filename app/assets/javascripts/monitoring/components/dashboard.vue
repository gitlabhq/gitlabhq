<script>
  /* global Flash */
  import _ from 'underscore';
  import MonitoringService from '../services/monitoring_service';
  import GraphGroup from './graph_group.vue';
  import Graph from './graph.vue';
  import EmptyState from './empty_state.vue';
  import MonitoringStore from '../stores/monitoring_store';
  import eventHub from '../event_hub';
  import { convertPermissionToBoolean } from '../../lib/utils/common_utils';

  export default {

    data() {
      const metricsData = document.querySelector('#prometheus-graphs').dataset;
      const store = new MonitoringStore();

      return {
        store,
        state: 'gettingStarted',
        hasMetrics: convertPermissionToBoolean(metricsData.hasMetrics),
        documentationPath: metricsData.documentationPath,
        settingsPath: metricsData.settingsPath,
        metricsEndpoint: metricsData.additionalMetrics,
        deploymentEndpoint: metricsData.deploymentEndpoint,
        emptyGettingStartedSvgPath: metricsData.emptyGettingStartedSvgPath,
        emptyLoadingSvgPath: metricsData.emptyLoadingSvgPath,
        emptyUnableToConnectSvgPath: metricsData.emptyUnableToConnectSvgPath,
        showEmptyState: true,
        updateAspectRatio: false,
        updatedAspectRatios: 0,
        resizeThrottled: {},
      };
    },

    components: {
      Graph,
      GraphGroup,
      EmptyState,
    },

    methods: {
      getGraphsData() {
        this.state = 'loading';
        Promise.all([
          this.service.getGraphsData()
            .then(data => this.store.storeMetrics(data)),
          this.service.getDeploymentData()
            .then(data => this.store.storeDeploymentData(data))
            .catch(() => new Flash('Error getting deployment information.')),
        ])
          .then(() => { this.showEmptyState = false; })
          .catch(() => { this.state = 'unableToConnect'; });
      },

      resize() {
        this.updateAspectRatio = true;
      },

      toggleAspectRatio() {
        this.updatedAspectRatios = this.updatedAspectRatios += 1;
        if (this.store.getMetricsCount() === this.updatedAspectRatios) {
          this.updateAspectRatio = !this.updateAspectRatio;
          this.updatedAspectRatios = 0;
        }
      },
    },

    created() {
      this.service = new MonitoringService({
        metricsEndpoint: this.metricsEndpoint,
        deploymentEndpoint: this.deploymentEndpoint,
      });
      eventHub.$on('toggleAspectRatio', this.toggleAspectRatio);
    },

    beforeDestroy() {
      eventHub.$off('toggleAspectRatio', this.toggleAspectRatio);
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
  };
</script>

<template>
  <div v-if="!showEmptyState" class="prometheus-graphs">
    <graph-group
      v-for="(groupData, index) in store.groups"
      :key="index"
      :name="groupData.group"
    >
      <graph
        v-for="(graphData, index) in groupData.metrics"
        :key="index"
        :graph-data="graphData"
        :update-aspect-ratio="updateAspectRatio"
        :deployment-data="store.deploymentData"
      />
    </graph-group>
  </div>
  <empty-state
    v-else
    :selected-state="state"
    :documentation-path="documentationPath"
    :settings-path="settingsPath"
    :empty-getting-started-svg-path="emptyGettingStartedSvgPath"
    :empty-loading-svg-path="emptyLoadingSvgPath"
    :empty-unable-to-connect-svg-path="emptyUnableToConnectSvgPath"
  />
</template>
