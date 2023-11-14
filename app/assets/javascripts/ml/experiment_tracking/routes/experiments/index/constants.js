import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export const CREATE_EXPERIMENT_HELP_PATH = helpPagePath(
  'user/project/ml/experiment_tracking/index',
  {
    anchor: 'track-new-experiments-and-candidates',
  },
);

export const EXPERIMENTS_TABLE_FIELDS = Object.freeze([
  { key: 'nameColumn', label: s__('MlExperimentTracking|Experiment') },
  {
    key: 'candidateCountColumn',
    label: s__('MlExperimentTracking|Logged candidates for experiment'),
  },
]);
