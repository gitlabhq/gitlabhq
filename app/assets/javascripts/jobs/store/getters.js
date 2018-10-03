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
 * When job has not started the key will be `false`
 * When job started the key will be a string with a date.
 */
export const jobHasStarted = state => !(state.job.started === false);

export const hasEnvironment = state => !_.isEmpty(state.job.deployment_status);

/**
 * When the job is pending and there are no available runners
 * we need to render the stuck block;
 *
 * @returns {Boolean}
 */
export const isJobStuck = state =>
  state.job.status.group === 'pending' && state.job.runners && state.job.runners.available === false;

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
