<script>
  import statusCodes from '~/lib/utils/http_status';
  import MonitoringService from '../services/monitoring_service';
  import MonitoringRow from './monitoring_row.vue';
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
        hasMetrics: gl.utils.convertPermissionToBoolean(metricsData.hasMetrics),
        endpoint: metricsData.additionalMetrics,
        showEmptyState: true,
        backOffRequestCounter: 0,
        service: {},
        updateAspectRatio: false,
        updatedAspectRatios: 0,
        prometheusStateContainer: $prometheusStateContainer,
      };
    },

    components: {
      'monitoring-row': MonitoringRow,
    },

    methods: {
      displayState() {
        let state;
        if (this.gettingStarted) {
          state = this.prometheusStateContainer.querySelector('.js-getting-started');
        } else if (this.unableToConnect) {
          state = this.prometheusStateContainer.querySelector('.js-unable-to-connect');
        } else if (this.isLoading) {
          state = this.prometheusStateContainer.querySelector('.js-loading');
        }

        if (!this.showEmptyState) {
          state.classList.add('hidden');
        } else {
          state.classList.remove('hidden');
        }
      },
      getGraphsData() {
        const maxNumberOfRequests = 3;
        this.displayState();
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
            return {};
          }
          return resp.json();
        })
        .then((resp) => {
          if (resp !== {}) {
            this.store.storeMetrics(resp.data);
            this.showEmptyState = false;
            this.displayState();
          }
        })
        .catch(() => {
          this.isLoading = false;
          this.unableToConnect = true;
          this.displayState();
        });
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
      this.service = new MonitoringService(this.endpoint);
      eventHub.$on('toggleAspectRatio', this.toggleAspectRatio);
    },

    beforeDestroyed() {
      eventHub.$off('toggleAspectRatio');
    },

    mounted() {
      if (!this.hasMetrics) {
        this.isLoading = false;
        this.gettingStarted = true;
        this.displayState();
      } else {
        this.getGraphsData();
        window.addEventListener('resize', this.resizeThrottler, false);
      }
    },
  };
</script>
<template>
  <div class="prometheus-graphs" v-show="!showEmptyState">
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
</template>
