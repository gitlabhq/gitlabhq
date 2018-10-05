import AlertWidget from './alert_widget.vue';
import ThresholdLines from './threshold_lines.vue';

export default {
  components: {
    AlertWidget,
    ThresholdLines,
  },
  props: {
    alertsEndpoint: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      alertData: {},
    };
  },
  methods: {
    getGraphLabel(graphData) {
      if (!graphData.queries || !graphData.queries[0]) return undefined;
      return graphData.queries[0].label || graphData.y_label || 'Average';
    },
    getQueryAlerts(graphData) {
      if (!graphData.queries) return [];
      return graphData.queries.map(query => query.alert_path).filter(Boolean);
    },
    setAlerts(metricId, alertData) {
      this.$set(this.alertData, metricId, alertData);
    },
  },
};
