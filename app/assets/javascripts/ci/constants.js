import { __ } from '~/locale';

export const forwardDeploymentFailureModalId = 'forward-deployment-failure';

export const JOB_GRAPHQL_ERRORS = {
  jobMutationErrorText: __('There was an error running the job. Please try again.'),
  jobQueryErrorText: __('There was an error fetching the job.'),
};

export const SUCCESS_STATUS = 'SUCCESS';
export const PASSED_STATUS = 'passed';
export const MANUAL_STATUS = 'manual';
