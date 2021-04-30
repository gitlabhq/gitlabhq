/**
 * @param {Object} environment
 * @returns {Object}
 */
export const setDeployBoard = (oldEnvironmentState, environment) => {
  let parsedEnvironment = environment;
  if (!environment.isFolder && environment.rollout_status) {
    parsedEnvironment = {
      ...environment,
      hasDeployBoard: true,
      isDeployBoardVisible:
        oldEnvironmentState.isDeployBoardVisible === false
          ? oldEnvironmentState.isDeployBoardVisible
          : true,
      deployBoardData:
        environment.rollout_status.status === 'found' ? environment.rollout_status : {},
      isLoadingDeployBoard: environment.rollout_status.status === 'loading',
      isEmptyDeployBoard: environment.rollout_status.status === 'not_found',
    };
  }
  return parsedEnvironment;
};
