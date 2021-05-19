import { isEmpty } from 'lodash';
import Visibility from 'visibilityjs';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { unwrapStagesWithNeedsAndLookup } from '../unwrapping_utils';

const addMulti = (mainPipelineProjectPath, linkedPipeline) => {
  return {
    ...linkedPipeline,
    multiproject: mainPipelineProjectPath !== linkedPipeline.project.fullPath,
  };
};

/* eslint-disable @gitlab/require-i18n-strings */
const getQueryHeaders = (etagResource) => {
  return {
    fetchOptions: {
      method: 'GET',
    },
    headers: {
      'X-GITLAB-GRAPHQL-FEATURE-CORRELATION': 'verify/ci/pipeline-graph',
      'X-GITLAB-GRAPHQL-RESOURCE-ETAG': etagResource,
      'X-Requested-With': 'XMLHttpRequest',
    },
  };
};

const serializeGqlErr = (gqlError) => {
  const { locations = [], message = '', path = [] } = gqlError;

  return `
    ${message}.
    Locations: ${locations
      .flatMap((loc) => Object.entries(loc))
      .flat(2)
      .join(' ')}.
    Path: ${path.join(', ')}.
  `;
};

const serializeLoadErrors = (errors) => {
  const { gqlError, graphQLErrors, networkError, message } = errors;

  if (!isEmpty(graphQLErrors)) {
    return graphQLErrors.map((err) => serializeGqlErr(err)).join('; ');
  }

  if (!isEmpty(gqlError)) {
    return serializeGqlErr(gqlError);
  }

  if (!isEmpty(networkError)) {
    return `Network error: ${networkError.message}`;
  }

  return message;
};

/* eslint-enable @gitlab/require-i18n-strings */

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

  const { stages: updatedStages, lookup } = unwrapStagesWithNeedsAndLookup(stages);

  return {
    ...pipeline,
    id: getIdFromGraphQLId(pipeline.id),
    stages: updatedStages,
    stagesLookup: lookup,
    upstream: upstream
      ? [upstream].map(addMulti.bind(null, mainPipelineProjectPath)).map(transformId)
      : [],
    downstream: downstream
      ? downstream.nodes.map(addMulti.bind(null, mainPipelineProjectPath)).map(transformId)
      : [],
  };
};

const validateConfigPaths = (value) => value.graphqlResourceEtag?.length > 0;

export {
  getQueryHeaders,
  serializeGqlErr,
  serializeLoadErrors,
  toggleQueryPollingByVisibility,
  unwrapPipelineData,
  validateConfigPaths,
};
