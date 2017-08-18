<script>
  /* global Flash */
  import _ from 'underscore';
  import statusCodes from '../../lib/utils/http_status';
  import MonitoringService from '../services/monitoring_service';
  import monitoringRow from './monitoring_row.vue';
  import monitoringState from './monitoring_state.vue';
  import MonitoringStore from '../stores/monitoring_store';
  import eventHub from '../event_hub';

  export default {

    data() {
      const metricsData = document.querySelector('#prometheus-graphs').dataset;
      const store = new MonitoringStore();

      return {
        store,
        state: 'gettingStarted',
        hasMetrics: gl.utils.convertPermissionToBoolean(metricsData.hasMetrics),
        documentationPath: metricsData.documentationPath,
        settingsPath: metricsData.settingsPath,
        endpoint: metricsData.additionalMetrics,
        deploymentEndpoint: metricsData.deploymentEndpoint,
        showEmptyState: true,
        backOffRequestCounter: 0,
        updateAspectRatio: false,
        updatedAspectRatios: 0,
        resizeThrottled: {},
      };
    },

    components: {
      monitoringRow,
      monitoringState,
    },

    methods: {
      getGraphsData() {
        const maxNumberOfRequests = 3;
        this.state = 'loading';
        gl.utils.backOff((next, stop) => {
          this.service.get().then((resp) => {
            if (resp.status === statusCodes.NO_CONTENT) {
              this.backOffRequestCounter = this.backOffRequestCounter += 1;
              if (this.backOffRequestCounter < maxNumberOfRequests) {
                next();
              } else {
                stop(new Error('Failed to connect to the prometheus server'));
              }
            } else {
              stop(resp);
            }
          }).catch(stop);
        })
        .then((resp) => {
          if (resp.status === statusCodes.NO_CONTENT) {
            this.state = 'unableToConnect';
            return false;
          }
          return resp.json();
        })
        .then((metricGroupsData) => {
          if (!metricGroupsData) return false;
          this.store.storeMetrics(metricGroupsData.data);
          return this.getDeploymentData();
        })
        .then((deploymentData) => {
          if (deploymentData !== false) {
            this.store.storeDeploymentData(deploymentData.deployments);
            this.showEmptyState = false;
          }
          return {};
        })
        .catch(() => {
          this.state = 'unableToConnect';
        });
      },

      getDeploymentData() {
        return this.service.getDeploymentData(this.deploymentEndpoint)
          .then(resp => resp.json())
          .catch(() => new Flash('Error getting deployment information.'));
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
      this.service = new MonitoringService(this.endpoint);
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
  <div 
    class="prometheus-graphs" 
    v-if="!showEmptyState">
    <div 
      class="row"
      v-for="(groupData, index) in store.groups"
      :key="index">
      <div 
        class="col-md-12">
        <div 
          class="panel panel-default prometheus-panel">
          <div 
            class="panel-heading">
            <h4>{{groupData.group}}</h4>
          </div>
          <div 
            class="panel-body">
            <monitoring-row
              v-for="(row, index) in groupData.metrics" 
              :key="index"
              :row-data="row"
              :update-aspect-ratio="updateAspectRatio"
              :deployment-data="store.deploymentData"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
  <monitoring-state 
    :selected-state="state"
    :documentation-path="documentationPath"
    :settings-path="settingsPath"
    v-else
  />
</template>
