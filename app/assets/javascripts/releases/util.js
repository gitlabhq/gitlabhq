import { pick } from 'lodash';
import createGqClient, { fetchPolicies } from '~/lib/graphql';
import { truncateSha } from '~/lib/utils/text_utility';

export const gqClient = createGqClient({}, { fetchPolicy: fetchPolicies.NO_CACHE });

const convertScalarProperties = (graphQLRelease) =>
  pick(graphQLRelease, [
    'name',
    'tagName',
    'tagPath',
    'description',
    'descriptionHtml',
    'upcomingRelease',
    'historicalRelease',
  ]);

const convertDateProperties = ({ createdAt, releasedAt }) => ({
  createdAt: new Date(createdAt),
  releasedAt: new Date(releasedAt),
});

const convertAssets = (graphQLRelease) => {
  let sources = [];
  if (graphQLRelease.assets.sources?.nodes) {
    sources = [...graphQLRelease.assets.sources.nodes];
  }

  let links = [];
  if (graphQLRelease.assets.links?.nodes) {
    links = graphQLRelease.assets.links.nodes.map((l) => ({
      ...l,
      linkType: l.linkType?.toLowerCase(),
    }));
  }

  return {
    assets: {
      count: graphQLRelease.assets.count,
      sources,
      links,
    },
  };
};

const convertEvidences = (graphQLRelease) => ({
  evidences: (graphQLRelease.evidences?.nodes ?? []).map((e) => ({ ...e })),
});

const convertLinks = (graphQLRelease) => ({
  _links: {
    ...graphQLRelease.links,
    self: graphQLRelease.links?.selfUrl,
  },
});

const convertCommit = (graphQLRelease) => {
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

const convertAuthor = (graphQLRelease) => ({ author: graphQLRelease.author });

const convertMilestones = (graphQLRelease) => ({
  milestones: graphQLRelease.milestones.nodes.map((m) => ({
    ...m,
    webUrl: m.webPath,
    webPath: undefined,
    issueStats: m.stats
      ? {
          total: m.stats.totalIssuesCount,
          closed: m.stats.closedIssuesCount,
        }
      : {},
    stats: undefined,
  })),
});

/**
 * Converts a single release object fetched from GraphQL
 * into a release object that matches the general structure of the REST API
 *
 * @param graphQLRelease The release object returned from a GraphQL query
 */
export const convertGraphQLRelease = (graphQLRelease) => ({
  ...convertScalarProperties(graphQLRelease),
  ...convertDateProperties(graphQLRelease),
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
export const convertAllReleasesGraphQLResponse = (response) => {
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
export const convertOneReleaseGraphQLResponse = (response) => {
  const release = convertGraphQLRelease(response.data.project.release);

  return { data: release };
};
