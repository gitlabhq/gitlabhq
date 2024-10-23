import { s__ } from '~/locale';

export const LIST_KEY_CREATED_AT = 'created_at';
export const LIST_KEY_VERSION = 'version';
export const SORT_KEY_CREATED_AT = 'CREATED_AT';
export const SORT_KEY_ORDER = 'DESC';

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

export const GRAPHQL_PAGE_SIZE = 30;

export const MODEL_ENTITIES = {
  model: 'model',
  modelVersion: 'modelVersion',
};

export const MLFLOW_USAGE_MODAL_ID = 'model-registry-mlflow-usage-modal';

export const emptyArtifactFile = {
  file: null,
  subfolder: '',
};

export const UPLOAD_STATUS = {
  CREATING: 0,
  PROCESSING: 1,
  CANCELED: 2,
  FAILED: 3,
  SUCCEEDED: 4,
};
