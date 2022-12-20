import { getIdFromGraphQLId } from '~/graphql_shared/utils';

/**
 * This function transforms Commit object coming from GraphQL to object compatible with app/assets/javascripts/vue_shared/components/commit.vue author object
 * @param {Object} Commit
 * @returns {Object}
 */
export const getAuthorFromCommit = (commit) => {
  if (commit.author) {
    return {
      username: commit.author.name,
      path: commit.author.webUrl,
      avatar_url: commit.author.avatarUrl,
    };
  }
  return {
    username: commit.authorName,
    path: `mailto:${commit.authorEmail}`,
    avatar_url: commit.authorGravatar,
  };
};

/**
 * This function transforms deploymentNode object coming from GraphQL to object compatible with app/assets/javascripts/vue_shared/components/commit.vue
 * @param {Object} deploymentNode
 * @returns {Object}
 */
export const getCommitFromDeploymentNode = (deploymentNode) => {
  if (!deploymentNode.commit) {
    throw new Error("deploymentNode argument doesn't have 'commit' field", deploymentNode);
  }
  return {
    title: deploymentNode.commit.message,
    commitUrl: deploymentNode.commit.webUrl,
    shortSha: deploymentNode.commit.shortId,
    tag: deploymentNode.tag,
    commitRef: {
      name: deploymentNode.ref,
    },
    author: getAuthorFromCommit(deploymentNode.commit),
  };
};

/**
 * This function transforms deploymentNode object coming from GraphQL to object compatible with app/assets/javascripts/environments/environment_details/page.vue table
 * @param {Object} deploymentNode
 * @returns {Object}
 */
export const convertToDeploymentTableRow = (deploymentNode) => {
  return {
    status: deploymentNode.status.toLowerCase(),
    id: deploymentNode.iid,
    triggerer: deploymentNode.triggerer,
    commit: getCommitFromDeploymentNode(deploymentNode),
    job: deploymentNode.job && {
      webPath: deploymentNode.job.webPath,
      label: `${deploymentNode.job.name} (#${getIdFromGraphQLId(deploymentNode.job.id)})`,
    },
    created: deploymentNode.createdAt || '',
    deployed: deploymentNode.finishedAt || '',
  };
};
