import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_CI_PIPELINE, TYPENAME_CI_STAGE } from '~/graphql_shared/constants';

const hasDetailedStatus = (item) => {
  return Boolean(item.detailedStatus);
};

/**
 * Converts REST shaped downstreams to GraphQL shape
 *
 * @param {Array} pipelines - The downstream pipelines passed into legacy pipeline mini graph
 * @returns {Array} - GraphQL shaped downstream pipelines
 */
export const normalizeDownstreamPipelines = (pipelines) => {
  return pipelines.map((p) => {
    if (hasDetailedStatus(p)) {
      return p;
    }

    const { id, details, path, project } = p;
    return {
      id: convertToGraphQLId(TYPENAME_CI_PIPELINE, id),
      detailedStatus: details?.status,
      path,
      project: {
        name: project.name,
      },
    };
  });
};

/**
 * Converts REST shaped pipeline stages to GraphQL shape
 *
 * @param {Array} stages - The pipeline stages passed into legacy pipeline mini graph
 * @returns {Array} - GraphQL shaped pipeline stages
 */
export const normalizeStages = (stages) => {
  return stages.map((s) => {
    if (hasDetailedStatus(s)) {
      return s;
    }

    const { id, name, status } = s;
    return {
      id: convertToGraphQLId(TYPENAME_CI_STAGE, id),
      detailedStatus: {
        icon: status.icon,
        label: status.label,
        tooltip: status.tooltip,
      },
      name,
    };
  });
};
