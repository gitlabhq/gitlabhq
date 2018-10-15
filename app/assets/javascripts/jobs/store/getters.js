import _ from 'underscore';
import { __ } from '~/locale';

export const headerActions = state => {
  if (state.job.new_issue_path) {
    return [
      {
        label: __('New issue'),
        path: state.job.new_issue_path,
        cssClass:
          'js-new-issue btn btn-success btn-inverted d-none d-md-block d-lg-block d-xl-block',
        type: 'link',
      },
    ];
  }
  return [];
};

export const headerTime = state => (state.job.started ? state.job.started : state.job.created_at);

export const shouldRenderCalloutMessage = state =>
  !_.isEmpty(state.job.status) && !_.isEmpty(state.job.callout_message);

/**
 * When job has not started the key will be null
 * When job started the key will be a string with a date.
 */
export const shouldRenderTriggeredLabel = state => _.isString(state.job.started);

export const hasEnvironment = state => !_.isEmpty(state.job.deployment_status);

/**
 * Checks if it the job has trace.
 * Used to check if it should render the job log or the empty state
 * @returns {Boolean}
 */
export const hasTrace = state => state.job.has_trace || state.job.status.group === 'running';

export const emptyStateIllustration = state =>
  (state.job && state.job.status && state.job.status.illustration) || {};

/**
 * When the job is pending and there are no available runners
 * we need to render the stuck block;
 *
 * @returns {Boolean}
 */
export const isJobStuck = state =>
  state.job.status.group === 'pending' &&
  (!_.isEmpty(state.job.runners) && state.job.runners.available === false);

// ee-only start
/**
 * Shared runners limit is only rendered when
 * used quota is bigger or equal than the limit
 *
 * @returns {Boolean}
 */
export const shouldRenderSharedRunnerLimitWarning = state =>
  !_.isEmpty(state.job.runners) &&
  !_.isEmpty(state.job.runners.quota) &&
  state.job.runners.quota.used >= state.job.runners.quota.limit;
// ee-only end

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
