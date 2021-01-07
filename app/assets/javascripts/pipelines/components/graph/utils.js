import Visibility from 'visibilityjs';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import * as Sentry from '~/sentry/wrapper';
import { unwrapStagesWithNeeds } from '../unwrapping_utils';

const addMulti = (mainPipelineProjectPath, linkedPipeline) => {
  return {
    ...linkedPipeline,
    multiproject: mainPipelineProjectPath !== linkedPipeline.project.fullPath,
  };
};

const transformId = (linkedPipeline) => {
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

const toggleQueryPollingByVisibility = (queryRef, interval = 10000) => {
  const stopStartQuery = (query) => {
    if (!Visibility.hidden()) {
      query.startPolling(interval);
    } else {
      query.stopPolling();
    }
  };

  stopStartQuery(queryRef);
  Visibility.change(stopStartQuery.bind(null, queryRef));
};

export { unwrapPipelineData, toggleQueryPollingByVisibility };

export const reportToSentry = (component, failureType) => {
  Sentry.withScope((scope) => {
    scope.setTag('component', component);
    Sentry.captureException(failureType);
  });
};
