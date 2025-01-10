import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export const FEATURE_NAME = s__('MlExperimentTracking|Machine learning experiment tracking');

export const FEATURE_FEEDBACK_ISSUE = 'https://gitlab.com/gitlab-org/gitlab/-/issues/381660';
export const ROUTE_DETAILS = 'details';
export const ROUTE_CANDIDATES = 'candidates';
export const ROUTE_PERFORMANCE = 'performance';
export const GRAPHQL_PAGE_SIZE = 30;
export const CANDIDATES_DOCS_PATH = helpPagePath(
  'user/project/ml/experiment_tracking/mlflow_client.md',
  { anchor: 'logging-runs-to-a-model' },
);
