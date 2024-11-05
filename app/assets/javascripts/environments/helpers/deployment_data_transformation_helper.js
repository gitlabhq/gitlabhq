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

export const convertJobToDeploymentAction = (job) => {
  return {
    name: job.name,
    playable: job.playable,
    scheduledAt: job.scheduledAt,
    playPath: `${job.webPath}/play`,
  };
};

export const getActionsFromDeploymentNode = (deploymentNode, lastDeploymentName) => {
  if (!deploymentNode || !lastDeploymentName) {
    return [];
  }

  return (
    deploymentNode.job?.deploymentPipeline?.jobs?.nodes
      ?.filter((deployment) => deployment.name !== lastDeploymentName)
      .map(convertJobToDeploymentAction) || []
  );
};

export const getRollbackActionFromDeploymentNode = (deploymentNode, environment) => {
  const { job, id } = deploymentNode;

  if (!job) {
    return null;
  }
  const isLastDeployment = id === environment.lastDeployment?.id;
  const { webPath } = job;
  return {
    id,
    name: environment.name,
    lastDeployment: {
      commit: deploymentNode.commit,
      isLast: isLastDeployment,
    },
    retryUrl: `${webPath}/retry`,
  };
};

const getDeploymentApprovalFromDeploymentNode = (deploymentNode, environment) => {
  if (!environment.protectedEnvironments || environment.protectedEnvironments.nodes.length === 0) {
    return {
      isApprovalActionAvailable: false,
    };
  }

  const protectedEnvironmentInfo = environment.protectedEnvironments.nodes[0];

  const hasApprovalRules = protectedEnvironmentInfo.approvalRules.nodes?.length > 0;
  const hasRequiredApprovals = protectedEnvironmentInfo.requiredApprovalCount > 0;

  const isApprovalActionAvailable = hasRequiredApprovals || hasApprovalRules;
  const requiredMultipleApprovalRulesApprovals =
    protectedEnvironmentInfo.approvalRules.nodes.reduce((requiredApprovals, rule) => {
      return requiredApprovals + rule.requiredApprovals;
    }, 0);

  const requiredApprovalCount = hasRequiredApprovals
    ? protectedEnvironmentInfo.requiredApprovalCount
    : requiredMultipleApprovalRulesApprovals;

  return {
    isApprovalActionAvailable,
    deploymentIid: deploymentNode.iid,
    environment: {
      name: environment.name,
      tier: environment.tier,
      requiredApprovalCount,
    },
  };
};

/**
 * This function transforms deploymentNode object coming from GraphQL to object compatible with app/assets/javascripts/environments/environment_details/page.vue table
 * @param {Object} deploymentNode
 * @returns {Object}
 */
export const convertToDeploymentTableRow = (deploymentNode, environment) => {
  const { lastDeployment } = environment;
  const commit = getCommitFromDeploymentNode(deploymentNode);
  return {
    status: deploymentNode.status.toLowerCase(),
    id: deploymentNode.iid,
    triggerer: deploymentNode.triggerer,
    commit,
    job: deploymentNode.job && {
      webPath: deploymentNode.job.webPath,
      label: `${deploymentNode.job.name} (#${getIdFromGraphQLId(deploymentNode.job.id)})`,
    },
    created: deploymentNode.createdAt || '',
    finished: deploymentNode.finishedAt || '',
    actions: getActionsFromDeploymentNode(deploymentNode, lastDeployment?.job?.name),
    rollback: getRollbackActionFromDeploymentNode(deploymentNode, environment),
    deploymentApproval: getDeploymentApprovalFromDeploymentNode(deploymentNode, environment),
    webPath: deploymentNode.webPath || '',
  };
};
