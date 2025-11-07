export const updatePipelineNodes = (pipelines = [], updatedPipeline = {}) => {
  return pipelines.map((pipeline) => {
    if (pipeline.id === updatedPipeline.id) {
      return {
        ...pipeline,
        ...updatedPipeline,
      };
    }

    return pipeline;
  });
};
