<script>
  /* global Flash */
  import _ from 'underscore';
  import statusCodes from '~/lib/utils/http_status';
  import MonitoringService from '../services/monitoring_service';
  import monitoringRow from './monitoring_row.vue';
  import MonitoringStore from '../stores/monitoring_store';
  import eventHub from '../event_hub';

  export default {

    data() {
      const metricsData = document.querySelector('.prometheus-graphs').dataset;
      const $prometheusStateContainer = document.querySelector('.prometheus-state');
      const store = new MonitoringStore();

      return {
        store,
        isLoading: true,
        unableToConnect: false,
        gettingStarted: false,
        state: '',
        hasMetrics: gl.utils.convertPermissionToBoolean(metricsData.hasMetrics),
        endpoint: metricsData.additionalMetrics,
        deploymentEndpoint: metricsData.deploymentEndpoint,
        showEmptyState: true,
        backOffRequestCounter: 0,
        updateAspectRatio: false,
        updatedAspectRatios: 0,
        prometheusStateContainer: $prometheusStateContainer,
      };
    },

    components: {
      monitoringRow,
    },

    methods: {
      updateState(prevState) {
        this.prometheusStateContainer.classList.add('hidden');
        if (prevState) {
          this.prometheusStateContainer.querySelector(prevState).classList.add('hidden');
        }
        this.prometheusStateContainer.querySelector(this.state).classList.remove('hidden');
        if (this.showEmptyState) {
          this.prometheusStateContainer.classList.remove('hidden');
        }
      },
      getGraphsData() {
        const maxNumberOfRequests = 3;
        this.state = '.js-loading';
        this.updateState();
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
            const prevState = this.state;
            this.state = '.js-unable-to-connect';
            this.updateState(prevState);
            return false;
          }
          return resp.json();
        })
        .then((metricGroupsData) => {
          if (metricGroupsData !== false) {
            this.store.storeMetrics(metricGroupsData.data);
            return this.getDeploymentData();
          }
          return false;
        })
        .then((deploymentData) => {
          if (deploymentData !== false) {
            this.store.storeDeploymentData(deploymentData.deployments);
            this.showEmptyState = false;
            this.updateState();
          }
          return {};
        })
        .catch(() => {
          const prevState = this.state;
          this.state = '.js-unable-to-connect';
          this.updateState(prevState);
        });
      },

      getDeploymentData() {
        return this.service.getDeploymentData(this.deploymentEndpoint)
          .then(resp => resp.json())
          .catch(() => new Flash('Error getting deployment information.'));
      },

      resize() {
        // ignore resize events as long as an actualResizeHandler execution is in the queue
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
      eventHub.$off('toggleAspectRatio');
    },

    mounted() {
      const resizeThrottled = _.throttle(this.resize, 600);
      if (!this.hasMetrics) {
        const prevState = this.state;
        this.state = '.js-getting-started';
        this.updateState(prevState);
      } else {
        this.getGraphsData();
        window.addEventListener('resize', resizeThrottled, false);
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
      v-for="(groupData, index) in store.groups">
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
              v-for="(row, index) in groupData.metrics" :key="index"
              :row-data="row"
              :update-aspect-ratio="updateAspectRatio"
              :deployment-data="store.deploymentData"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
