import { isEmpty } from 'lodash';
import { checkJobHasLog } from './utils';

export const hasForwardDeploymentFailure = (state) =>
  state?.job?.failure_reason === 'forward_deployment_failure';

export const hasUnmetPrerequisitesFailure = (state) =>
  state?.job?.failure_reason === 'unmet_prerequisites';

export const shouldRenderCalloutMessage = (state) =>
  !isEmpty(state.job.status) && !isEmpty(state.job.callout_message);

export const hasEnvironment = (state) => !isEmpty(state.job.deployment_status);

/**
 * Used to check if it should render the job log or the empty state
 *
 * @returns {Boolean}
 */
export const hasJobLog = (state) => checkJobHasLog(state);

export const emptyStateIllustration = (state) => state?.job?.status?.illustration || {};

export const emptyStateAction = (state) => state?.job?.status?.action || null;

/**
 * Instance/shared runners limit is only rendered when
 * used quota is bigger or equal than the limit
 *
 * @returns {Boolean}
 */
export const shouldRenderSharedRunnerLimitWarning = (state) =>
  !isEmpty(state.job.runners) &&
  !isEmpty(state.job.runners.quota) &&
  state.job.runners.quota.used >= state.job.runners.quota.limit;

export const hasOfflineRunnersForProject = (state) =>
  state?.job?.runners?.available && !state?.job?.runners?.online;

export const fullScreenAPIAndContainerAvailable = (state) =>
  state.fullScreenAPIAvailable && state.fullScreenModeAvailable;
