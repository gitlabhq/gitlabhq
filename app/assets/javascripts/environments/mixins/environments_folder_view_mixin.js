export default {
  props: {
    canaryDeploymentFeatureId: {
      type: String,
      required: false,
      default: '',
    },
    showCanaryDeploymentCallout: {
      type: Boolean,
      required: false,
      default: false,
    },
    userCalloutsPath: {
      type: String,
      required: false,
      default: '',
    },
    lockPromotionSvgPath: {
      type: String,
      required: false,
      default: '',
    },
    helpCanaryDeploymentsPath: {
      type: String,
      required: false,
      default: '',
    },
  },
};
