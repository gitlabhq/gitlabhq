import { PIPELINES_PER_PAGE } from './constants';

export const updatePipelineNodes = (pipelines = [], updatedPipeline = {}) => {
  // Check if this pipeline already exists in the list
  const existingPipelineIndex = pipelines.findIndex(
    (pipeline) => pipeline.id === updatedPipeline.id,
  );

  // If pipeline exists, update it in place
  if (existingPipelineIndex !== -1) {
    return pipelines.map((pipeline) => {
      if (pipeline.id === updatedPipeline.id) {
        return {
          ...pipeline,
          ...updatedPipeline,
        };
      }
      return pipeline;
    });
  }

  // If pipeline doesn't exist, it's a new pipeline
  const newPipelines = [updatedPipeline, ...pipelines];

  // Trim to page limit if exceeded
  if (newPipelines.length > PIPELINES_PER_PAGE) {
    return newPipelines.slice(0, PIPELINES_PER_PAGE);
  }

  return newPipelines;
};
