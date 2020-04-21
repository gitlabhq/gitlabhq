<script>
import CeDashboard from '~/monitoring/components/dashboard.vue';
import AlertWidget from './alert_widget.vue';

export default {
  components: {
    AlertWidget,
  },
  extends: CeDashboard,
  data() {
    return {
      allAlerts: {},
    };
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
