import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export const METRIC_KEY_PREFIX = 'metric.';
export const LIST_KEY_CREATED_AT = 'created_at';
export const BASE_SORT_FIELDS = Object.freeze([
  {
    orderBy: 'name',
    label: s__('MlExperimentTracking|Name'),
  },
  {
    orderBy: LIST_KEY_CREATED_AT,
    label: s__('MlExperimentTracking|Created at'),
  },
]);
export const CREATE_CANDIDATE_HELP_PATH = helpPagePath(
  'user/project/ml/experiment_tracking/index.md',
  {
    anchor: 'tracking-new-experiments-and-trials',
  },
);
