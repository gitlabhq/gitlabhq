import { isEmpty } from 'lodash';
import { getIdFromGraphQLId, etagQueryHeaders } from '~/graphql_shared/utils';
import { reportToSentry } from '~/ci/utils';

import { listByLayers } from '~/ci/pipeline_details/utils/parsing_utils';
import { unwrapStagesWithNeedsAndLookup } from '~/ci/pipeline_details/utils/unwrapping_utils';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { sanitize } from '~/lib/dompurify';
import { __, s__, sprintf } from '~/locale';
import { beginPerfMeasure, finishPerfMeasureAndSend } from './perf_utils';

export { toggleQueryPollingByVisibility } from '~/graphql_shared/utils';

const addMulti = (mainPipelineProjectPath, linkedPipeline) => {
  return {
    ...linkedPipeline,
    multiproject: mainPipelineProjectPath !== linkedPipeline.project.fullPath,
  };
};

const calculatePipelineLayersInfo = (pipeline, componentName, metricsPath) => {
  const shouldCollectMetrics = Boolean(metricsPath);

  if (shouldCollectMetrics) {
    beginPerfMeasure();
  }

  let layers = null;

  try {
    layers = listByLayers(pipeline);

    if (shouldCollectMetrics) {
      finishPerfMeasureAndSend(layers.linksData.length, layers.numGroups, metricsPath);
    }
  } catch (err) {
    reportToSentry(componentName, err);
  }

  return layers;
};

const getQueryHeaders = (etagResource) =>
  etagQueryHeaders('verify/ci/pipeline-graph', etagResource);

const serializeGqlErr = (gqlError) => {
  const { locations = [], message = '', path = [] } = gqlError;

  // eslint-disable-next-line @gitlab/require-i18n-strings
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
    return `Network error: ${networkError.message}`; // eslint-disable-line @gitlab/require-i18n-strings
  }

  return message;
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

const confirmJobConfirmationMessage = (jobName, message) => {
  return confirmAction(null, {
    title: sprintf(s__('PipelineGraph|Are you sure you want to run %{jobName}?'), {
      jobName: sanitize(jobName),
    }),
    modalHtmlMessage: `
      <p>${sprintf(__('Custom confirmation message: %{message}'), {
        message: sanitize(message),
      })}</p>
      <p>${s__('PipelineGraph|Do you want to continue?')}</p>
    `,
    primaryBtnText: sprintf(__('Yes, run %{jobName}'), {
      jobName: sanitize(jobName),
    }),
  });
};

export {
  calculatePipelineLayersInfo,
  getQueryHeaders,
  serializeGqlErr,
  serializeLoadErrors,
  unwrapPipelineData,
  validateConfigPaths,
  confirmJobConfirmationMessage,
};
