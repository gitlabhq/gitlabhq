import { __, s__ } from '~/locale';

export const METRIC_KEY_PREFIX = 'metric.';

export const LIST_KEY_CREATED_AT = 'created_at';

export const BASE_SORT_FIELDS = Object.freeze([
  {
    orderBy: 'name',
    label: __('Name'),
  },
  {
    orderBy: LIST_KEY_CREATED_AT,
    label: __('Created at'),
  },
]);

export const EMPTY_STATE_SVG = '/assets/illustrations/empty-state/empty-dag-md.svg';

export const FEATURE_NAME = s__('MlExperimentTracking|Machine learning experiment tracking');

export const FEATURE_FEEDBACK_ISSUE = 'https://gitlab.com/gitlab-org/gitlab/-/issues/381660';
