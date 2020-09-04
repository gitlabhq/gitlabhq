import { parseBoolean } from '~/lib/utils/common_utils';

export default {
  data() {
    const data = this.$options.el.dataset;

    return {
      canaryDeploymentFeatureId: data.environmentsDataCanaryDeploymentFeatureId,
      showCanaryDeploymentCallout: parseBoolean(data.environmentsDataShowCanaryDeploymentCallout),
      userCalloutsPath: data.environmentsDataUserCalloutsPath,
      lockPromotionSvgPath: data.environmentsDataLockPromotionSvgPath,
      helpCanaryDeploymentsPath: data.environmentsDataHelpCanaryDeploymentsPath,
    };
  },
  computed: {
    canaryCalloutProps() {
      return {
        canaryDeploymentFeatureId: this.canaryDeploymentFeatureId,
        showCanaryDeploymentCallout: this.showCanaryDeploymentCallout,
        userCalloutsPath: this.userCalloutsPath,
        lockPromotionSvgPath: this.lockPromotionSvgPath,
        helpCanaryDeploymentsPath: this.helpCanaryDeploymentsPath,
      };
    },
  },
};
