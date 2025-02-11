import { convertToGraphQLId } from '~/graphql_shared/utils';
import { cleanLeadingSeparator } from '~/lib/utils/url_utility';
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

    const { id, iid, details, name, path, project } = p;
    return {
      id: convertToGraphQLId(TYPENAME_CI_PIPELINE, id),
      iid,
      detailedStatus: details?.status,
      name,
      path,
      project: {
        fullPath: cleanLeadingSeparator(project.full_path),
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

/**
 * sorts jobs by status
 * failed > manual > everything else > success
 *
 * @param {Array} jobs - The jobs to sort
 * @returns {Array} - The sorted jobs
 */
export const sortJobsByStatus = (jobs) => {
  if (!jobs) return [];
  return [...jobs].sort((a, b) => {
    const order = { failed: -3, manual: -2, success: 1 };
    return (order[a.detailedStatus.group] || 0) - (order[b.detailedStatus.group] || 0);
  });
};
