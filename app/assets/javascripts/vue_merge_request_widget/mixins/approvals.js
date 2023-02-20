export default {
  data() {
    return {
      alerts: [],
    };
  },
  methods: {
    clearError() {
      this.$emit('clearError');
      this.hasApprovalAuthError = false;
      this.alerts.forEach((alert) => alert.dismiss());
      this.alerts = [];
    },
    refreshApprovals() {
      return this.service.fetchApprovals().then((data) => {
        this.mr.setApprovals(data);
      });
    },
  },
};
