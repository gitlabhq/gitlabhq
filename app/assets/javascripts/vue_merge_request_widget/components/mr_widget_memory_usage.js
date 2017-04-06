import statusCodes from '~/lib/utils/http_status';
import MemoryGraph from '../../vue_shared/components/memory_graph';

export default {
  name: 'MemoryUsage',
  props: {
    mr: { type: Object, required: true },
    service: { type: Object, required: true },
    metricsUrl: { type: String, required: true },
  },
  data() {
    return {
      memoryFrom: 0,
      memoryTo: 0,
      memoryMetrics: [],
      hasMetrics: false,
      loadingMetrics: true,
      backOffRequestCounter: 0,
    };
  },
  components: {
    'mr-memory-graph': MemoryGraph,
  },
  methods: {
    computeGraphData(metrics) {
      this.loadingMetrics = false;
      const { memory_previous, memory_current, memory_values } = metrics;
      if (memory_previous.length > 0) {
        this.memoryFrom = Number(memory_previous[0].value[1]).toFixed(2);
      }

      if (memory_current.length > 0) {
        this.memoryTo = Number(memory_current[0].value[1]).toFixed(2);
      }

      if (memory_values.length > 0) {
        this.hasMetrics = true;
        this.memoryMetrics = memory_values[0].values;
      }
    },
  },
  mounted() {
    this.$props.loadingMetrics = true;
    gl.utils.backOff((next, stop) => {
      this.service.fetchMetrics(this.$props.metricsUrl)
        .then((res) => {
          if (res.status === statusCodes.NO_CONTENT) {
            this.backOffRequestCounter = this.backOffRequestCounter += 1;
            if (this.backOffRequestCounter < 3) {
              next();
            } else {
              stop(res);
            }
          } else {
            stop(res);
          }
        })
        .catch(stop);
    })
    .then((res) => {
      if (res.status === statusCodes.NO_CONTENT) {
        return res;
      }

      return res.json();
    })
    .then((res) => {
      this.computeGraphData(res.metrics);
    });
  },
  template: `
    <div class="mr-info-list mr-memory-usage">
      <div class="legend"></div>
      <p class="usage-info usage-info-loading" v-if="loadingMetrics">
        <i class="fa fa-spinner fa-spin" aria-hidden="true"></i>Loading deployment statistics.
      </p>
      <p class="usage-info" v-if="hasMetrics">Memory increased from {{memoryFrom}} MB to {{memoryTo}} MB.</p>
      <mr-memory-graph v-if="hasMetrics" :height=25 :width=100 :metrics="memoryMetrics"></mr-memory-graph>
    </div>
  `,
};
