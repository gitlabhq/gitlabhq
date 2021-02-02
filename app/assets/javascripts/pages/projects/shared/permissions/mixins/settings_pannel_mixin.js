export default {
  data() {
    return {
      packagesEnabled: false,
      requirementsEnabled: false,
      securityAndComplianceEnabled: false,
    };
  },
  watch: {
    repositoryAccessLevel(value, oldValue) {
      if (value < oldValue) {
        // sub-features cannot have more premissive access level
        this.mergeRequestsAccessLevel = Math.min(this.mergeRequestsAccessLevel, value);
        this.buildsAccessLevel = Math.min(this.buildsAccessLevel, value);

        if (value === 0) {
          this.containerRegistryEnabled = false;
        }
      } else if (oldValue === 0) {
        this.mergeRequestsAccessLevel = value;
        this.buildsAccessLevel = value;
        this.containerRegistryEnabled = true;
        this.lfsEnabled = true;
      }
    },
  },
};
