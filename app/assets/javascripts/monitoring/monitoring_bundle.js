/* global Breakpoints */

import statusCodes from '~/lib/utils/http_status';
import '~/lib/utils/common_utils';
import Vue from 'vue';
import VueResource from 'vue-resource';
import d3 from 'd3';
import MonitoringService from './services/monitoring_service';
import MonitoringState from './components/monitoring_state.vue';
import MonitoringRow from './components/monitoring_row.vue';
import MonitoringStore from './stores/monitoring_store';
import eventHub from './event_hub';
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
        updateAspectRatio: false,
        updatedAspectRatios: 0,
      };
    },

    components: {
      'monitoring-state': MonitoringState,
      'monitoring-row': MonitoringRow,
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
      resizeThrottler() {
        // ignore resize events as long as an actualResizeHandler execution is in the queue
        if (!this.resizeTimeout) {
          this.resizeTimeout = setTimeout(() => {
            this.resizeTimeout = null;
            this.updateAspectRatio = true;
          }, 600);
        }
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
      this.service = new MonitoringService();
      eventHub.$on('toggleAspectRatio', this.toggleAspectRatio);
    },

    beforeDestroyed() {
      eventHub.$off('toggleAspectRatio');
    },

    mounted() {
      if (!this.hasMetrics) {
        this.isLoading = false;
        this.gettingStarted = true;
        this.showEmptyState = true;
      } else {
        // this.getGraphsData();
        this.getGraphsDataNewApiMock();
        window.addEventListener('resize', this.resizeThrottler, false);
      }
    },

    template: `
      <div class="prometheus-graphs" v-if="!showEmptyState">
        <div class="row"
          v-for="(groupData, index) in store.groups"
        >
          <div class="col-md-12">
            <div class="panel panel-default prometheus-panel">
              <div class="panel-heading">
                <h4>{{groupData.group}}</h4>
              </div>
              <div class="panel-body">
                <monitoring-row
                  v-for="(row, index) in groupData.metrics"
                  :rowData="row"
                  :key="index"
                  :updateAspectRatio="updateAspectRatio"
                />
              </div>
            </div>
          </div>
        </div>
      </div>
      <monitoring-state 
      :isLoading=isLoading 
      :unableToConnect=unableToConnect 
      :gettingStarted=gettingStarted 
      v-else />
    `,
  });
}, false);
