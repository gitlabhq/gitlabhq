import { pick } from 'lodash';
import createGqClient, { fetchPolicies } from '~/lib/graphql';
import { truncateSha } from '~/lib/utils/text_utility';
import {
  convertObjectPropsToCamelCase,
  convertObjectPropsToSnakeCase,
} from '~/lib/utils/common_utils';

/**
 * Converts a release object into a JSON object that can sent to the public
 * API to create or update a release.
 * @param {Object} release The release object to convert
 * @param {string} createFrom The ref to create a new tag from, if necessary
 */
export const releaseToApiJson = (release, createFrom = null) => {
  const name = release.name?.trim().length > 0 ? release.name.trim() : null;

  // Milestones may be either a list of milestone objects OR just a list
  // of milestone titles. The API requires only the titles be sent.
  const milestones = (release.milestones || []).map(m => m.title || m);

  return convertObjectPropsToSnakeCase(
    {
      name,
      tagName: release.tagName,
      ref: createFrom,
      description: release.description,
      milestones,
      assets: release.assets,
    },
    { deep: true },
  );
};

/**
 * Converts a JSON release object returned by the Release API
 * into the structure this Vue application can work with.
 * @param {Object} json The JSON object received from the release API
 */
export const apiJsonToRelease = json => {
  const release = convertObjectPropsToCamelCase(json, { deep: true });

  release.milestones = release.milestones || [];

  return release;
};

export const gqClient = createGqClient({}, { fetchPolicy: fetchPolicies.NO_CACHE });

const convertScalarProperties = graphQLRelease =>
  pick(graphQLRelease, [
    'name',
    'tagName',
    'tagPath',
    'descriptionHtml',
    'releasedAt',
    'upcomingRelease',
  ]);

const convertAssets = graphQLRelease => ({
  assets: {
    count: graphQLRelease.assets.count,
    sources: [...graphQLRelease.assets.sources.nodes],
    links: graphQLRelease.assets.links.nodes.map(l => ({
      ...l,
      linkType: l.linkType?.toLowerCase(),
    })),
  },
});

const convertEvidences = graphQLRelease => ({
  evidences: graphQLRelease.evidences.nodes.map(e => e),
});

const convertLinks = graphQLRelease => ({
  _links: {
    ...graphQLRelease.links,
    self: graphQLRelease.links?.selfUrl,
  },
});

const convertCommit = graphQLRelease => {
  if (!graphQLRelease.commit) {
    return {};
  }

  return {
    commit: {
      shortId: truncateSha(graphQLRelease.commit.sha),
      title: graphQLRelease.commit.title,
    },
    commitPath: graphQLRelease.commit.webUrl,
  };
};

const convertAuthor = graphQLRelease => ({ author: graphQLRelease.author });

const convertMilestones = graphQLRelease => ({
  milestones: graphQLRelease.milestones.nodes.map(m => ({
    ...m,
    webUrl: m.webPath,
    webPath: undefined,
    issueStats: {
      total: m.stats.totalIssuesCount,
      closed: m.stats.closedIssuesCount,
    },
    stats: undefined,
  })),
});

/**
 * Converts a single release object fetched from GraphQL
 * into a release object that matches the shape of the REST API
 * (the same shape that is returned by `apiJsonToRelease` above.)
 *
 * @param graphQLRelease The release object returned from a GraphQL query
 */
export const convertGraphQLRelease = graphQLRelease => ({
  ...convertScalarProperties(graphQLRelease),
  ...convertAssets(graphQLRelease),
  ...convertEvidences(graphQLRelease),
  ...convertLinks(graphQLRelease),
  ...convertCommit(graphQLRelease),
  ...convertAuthor(graphQLRelease),
  ...convertMilestones(graphQLRelease),
});

/**
 * Converts the response from all_releases.query.graphql into the
 * same shape as is returned from the Releases REST API.
 *
 * This allows the release components to use the response
 * from either endpoint interchangeably.
 *
 * @param response The response received from the GraphQL endpoint
 */
export const convertAllReleasesGraphQLResponse = response => {
  const releases = response.data.project.releases.nodes.map(convertGraphQLRelease);

  const paginationInfo = {
    ...response.data.project.releases.pageInfo,
  };

  return { data: releases, paginationInfo };
};

/**
 * Converts the response from one_release.query.graphql into the
 * same shape as is returned from the Releases REST API.
 *
 * This allows the release components to use the response
 * from either endpoint interchangeably.
 *
 * @param response The response received from the GraphQL endpoint
 */
export const convertOneReleaseGraphQLResponse = response => {
  const release = convertGraphQLRelease(response.data.project.release);

  return { data: release };
};
