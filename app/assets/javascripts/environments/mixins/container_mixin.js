export default {
  props: {
    canaryDeploymentFeatureId: {
      type: String,
      required: false,
      default: null,
    },
    showCanaryDeploymentCallout: {
      type: Boolean,
      required: false,
      default: false,
    },
    userCalloutsPath: {
      type: String,
      required: false,
      default: null,
    },
    lockPromotionSvgPath: {
      type: String,
      required: false,
      default: null,
    },
    helpCanaryDeploymentsPath: {
      type: String,
      required: false,
      default: null,
    },
    deployBoardsHelpPath: {
      type: String,
      required: false,
      default: '',
    },
  },
};
