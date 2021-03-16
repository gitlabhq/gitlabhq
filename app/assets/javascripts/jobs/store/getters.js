import { isEmpty, isString } from 'lodash';
import { isScrolledToBottom } from '~/lib/utils/scroll_utils';

export const headerTime = (state) => (state.job.started ? state.job.started : state.job.created_at);

export const hasForwardDeploymentFailure = (state) =>
  state?.job?.failure_reason === 'forward_deployment_failure';

export const hasUnmetPrerequisitesFailure = (state) =>
  state?.job?.failure_reason === 'unmet_prerequisites';

export const shouldRenderCalloutMessage = (state) =>
  !isEmpty(state.job.status) && !isEmpty(state.job.callout_message);

/**
 * When job has not started the key will be null
 * When job started the key will be a string with a date.
 */
export const shouldRenderTriggeredLabel = (state) => isString(state.job.started);

export const hasEnvironment = (state) => !isEmpty(state.job.deployment_status);

/**
 * Checks if it the job has trace.
 * Used to check if it should render the job log or the empty state
 * @returns {Boolean}
 */
export const hasTrace = (state) =>
  state.job.has_trace || (!isEmpty(state.job.status) && state.job.status.group === 'running');

export const emptyStateIllustration = (state) => state?.job?.status?.illustration || {};

export const emptyStateAction = (state) => state?.job?.status?.action || null;

/**
 * Shared runners limit is only rendered when
 * used quota is bigger or equal than the limit
 *
 * @returns {Boolean}
 */
export const shouldRenderSharedRunnerLimitWarning = (state) =>
  !isEmpty(state.job.runners) &&
  !isEmpty(state.job.runners.quota) &&
  state.job.runners.quota.used >= state.job.runners.quota.limit;

export const isScrollingDown = (state) => isScrolledToBottom() && !state.isTraceComplete;

export const hasRunnersForProject = (state) =>
  state?.job?.runners?.available && !state?.job?.runners?.online;
