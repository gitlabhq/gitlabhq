export default ({ modelIid, projectId } = {}) => ({
  // Initial state
  modelIid,
  projectId,

  // View state
  metricImages: [],
  isLoadingMetricImages: false,
  isUploadingImage: false,
});
