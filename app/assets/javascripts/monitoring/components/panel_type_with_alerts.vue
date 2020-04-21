<script>
import { mapGetters } from 'vuex';
import CustomMetricsFormFields from '~/custom_metrics/components/custom_metrics_form_fields.vue';
import CePanelType from '~/monitoring/components/panel_type.vue';
import AlertWidget from './alert_widget.vue';

export default {
  components: {
    AlertWidget,
    CustomMetricsFormFields,
  },
  extends: CePanelType,
  props: {
    alertsEndpoint: {
      type: String,
      required: false,
      default: null,
    },
    prometheusAlertsAvailable: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      allAlerts: {},
    };
  },
  computed: {
    ...mapGetters('monitoringDashboard', ['metricsSavedToDb']),
    hasMetricsInDb() {
      const { metrics = [] } = this.graphData;
      return metrics.some(({ metricId }) => this.metricsSavedToDb.includes(metricId));
    },
    alertWidgetAvailable() {
      return (
        this.prometheusAlertsAvailable &&
        this.alertsEndpoint &&
        this.graphData &&
        this.hasMetricsInDb
      );
    },
  },
  methods: {
    setAlerts(alertPath, alertAttributes) {
      if (alertAttributes) {
        this.$set(this.allAlerts, alertPath, alertAttributes);
      } else {
        this.$delete(this.allAlerts, alertPath);
      }
    },
  },
};
</script>
