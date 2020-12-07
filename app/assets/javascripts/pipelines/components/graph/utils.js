import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { unwrapStagesWithNeeds } from '../unwrapping_utils';

const addMulti = (mainPipelineProjectPath, linkedPipeline) => {
  return {
    ...linkedPipeline,
    multiproject: mainPipelineProjectPath !== linkedPipeline.project.fullPath,
  };
};

const transformId = linkedPipeline => {
  return { ...linkedPipeline, id: getIdFromGraphQLId(linkedPipeline.id) };
};

const unwrapPipelineData = (mainPipelineProjectPath, data) => {
  if (!data?.project?.pipeline) {
    return null;
  }

  const { pipeline } = data.project;

  const {
    upstream,
    downstream,
    stages: { nodes: stages },
  } = pipeline;

  const nodes = unwrapStagesWithNeeds(stages);

  return {
    ...pipeline,
    id: getIdFromGraphQLId(pipeline.id),
    stages: nodes,
    upstream: upstream
      ? [upstream].map(addMulti.bind(null, mainPipelineProjectPath)).map(transformId)
      : [],
    downstream: downstream
      ? downstream.nodes.map(addMulti.bind(null, mainPipelineProjectPath)).map(transformId)
      : [],
  };
};

export { unwrapPipelineData };
