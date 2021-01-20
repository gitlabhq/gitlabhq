import { hideFlash } from '~/flash';

export default {
  methods: {
    clearError() {
      this.$emit('clearError');
      this.hasApprovalAuthError = false;
      const flashEl = document.querySelector('.flash-alert');
      if (flashEl) {
        hideFlash(flashEl);
      }
    },
    refreshApprovals() {
      return this.service.fetchApprovals().then((data) => {
        this.mr.setApprovals(data);
      });
    },
  },
};
