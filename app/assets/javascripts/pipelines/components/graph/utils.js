import { unwrapStagesWithNeeds } from '../unwrapping_utils';

const addMulti = (mainId, pipeline) => {
  return { ...pipeline, multiproject: mainId !== pipeline.id };
};

const unwrapPipelineData = (mainPipelineId, data) => {
  if (!data?.project?.pipeline) {
    return null;
  }

  const {
    id,
    upstream,
    downstream,
    stages: { nodes: stages },
  } = data.project.pipeline;

  const nodes = unwrapStagesWithNeeds(stages);

  return {
    id,
    stages: nodes,
    upstream: upstream ? [upstream].map(addMulti.bind(null, mainPipelineId)) : [],
    downstream: downstream ? downstream.map(addMulti.bind(null, mainPipelineId)) : [],
  };
};

export { unwrapPipelineData };
