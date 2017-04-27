/* global Breakpoints */

import statusCodes from '~/lib/utils/http_status';
import '~/lib/utils/common_utils';
import Vue from 'vue';
import VueResource from 'vue-resource';
import d3 from 'd3';
import MonitoringService from './services/monitoring_service';
import MonitoringState from './components/monitoring_state.vue';
import MonitoringPanel from './components/monitoring_panel.vue';
import MonitoringStore from './stores/monitoring_store';
import MonitoringNewAPIResponse from './monitoring_mock';

Vue.use(VueResource);

document.addEventListener('DOMContentLoaded', function onLoad() {
  document.removeEventListener('DOMContentLoaded', onLoad, false);

  const $prometheusGraphs = document.querySelector('.prometheus-graphs');

  const PrometheusApp = new Vue({
    el: $prometheusGraphs,

    data() {
      const metricsData = $prometheusGraphs.dataset;
      const store = new MonitoringStore();

      return {
        store,
        isLoading: true,
        unableToConnect: false,
        gettingStarted: false,
        hasMetrics: gl.utils.convertPermissionToBoolean(metricsData.hasMetrics),
        showEmptyState: false,
        testValue: 0,
        endpoint: 'metrics.json',
        backOffRequestCounter: 0,
        bisectDate: d3.bisector(d => d.time).left,
        service: {},
      };
    },

    components: {
      'monitoring-state': MonitoringState,
      'monitoring-panel': MonitoringPanel,
    },

    methods: {
      getGraphsData() {
        const maxNumberOfRequests = 3;
        this.showEmptyState = true;
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
            this.isLoading = false;
            this.unableToConnect = true;
            this.showEmptyState = true;
            return resp;
          }
          return resp.json();
        })
        .then((resp) => {
          this.store.storeMetrics(resp.metrics);
          if (this.store.enoughMetrics) {
            this.showEmptyState = false;
          }
        })
        .catch(() => {
          this.isLoading = false;
          this.unableToConnect = true;
          this.showEmptyState = true;
        });
      },
      // TODO: Delete the following method, it's just for testing
      getGraphsDataNewApiMock() {
        this.showEmptyState = false;
        this.store.storeMetrics(MonitoringNewAPIResponse);
      },
      increaseValue() {
        this.testValue = this.testValue += 1;
      },
    },

    created() {
      this.service = new MonitoringService();
    },

    mounted() {
      if (!this.hasMetrics) {
        this.isLoading = false;
        this.gettingStarted = true;
        this.showEmptyState = true;
      } else {
        // this.getGraphsData();
        this.getGraphsDataNewApiMock();
      }
    },

    template: `
      <div class="prometheus-graphs" v-if="!showEmptyState">
        <button class="btn btn-primary" @click=increaseValue>
          Increase test value
        </button>
        <monitoring-panel
          v-for="(group, index) in store.groups" 
          :groupData="group"
          :key="index" 
        />
      </div>
      <monitoring-state 
      :isLoading=isLoading 
      :unableToConnect=unableToConnect 
      :gettingStarted=gettingStarted 
      v-else />
    `,
  });
}, false);

