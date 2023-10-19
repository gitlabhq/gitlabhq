import { __, s__ } from '~/locale';

export const TITLE_LABEL = s__('MlExperimentTracking|Model candidate details');
export const INFO_LABEL = s__('MlExperimentTracking|Info');
export const ID_LABEL = s__('MlExperimentTracking|ID');
export const MLFLOW_ID_LABEL = s__('MlExperimentTracking|MLflow run ID');
export const STATUS_LABEL = s__('MlExperimentTracking|Status');
export const EXPERIMENT_LABEL = s__('MlExperimentTracking|Experiment');
export const ARTIFACTS_LABEL = s__('MlExperimentTracking|Artifacts');
export const PARAMETERS_LABEL = s__('MlExperimentTracking|Parameters');
export const METRICS_LABEL = s__('MlExperimentTracking|Metrics');
export const PERFORMANCE_LABEL = s__('MlExperimentTracking|Model performance');
export const METADATA_LABEL = s__('MlExperimentTracking|Metadata');
export const NO_PARAMETERS_MESSAGE = s__('MlExperimentTracking|No logged parameters');
export const NO_METRICS_MESSAGE = s__('MlExperimentTracking|No logged metrics');
export const NO_METADATA_MESSAGE = s__('MlExperimentTracking|No logged metadata');
export const NO_CI_MESSAGE = s__('MlExperimentTracking|Candidate not linked to a CI build');
export const DELETE_CANDIDATE_CONFIRMATION_MESSAGE = s__(
  'MlExperimentTracking|Deleting this candidate will delete the associated parameters, metrics, and metadata.',
);
export const DELETE_CANDIDATE_PRIMARY_ACTION_LABEL = s__('MlExperimentTracking|Delete candidate');
export const DELETE_CANDIDATE_MODAL_TITLE = s__('MLExperimentTracking|Delete candidate?');
export const CI_SECTION_LABEL = s__('MLExperimentTracking|CI Info');
export const JOB_LABEL = __('Job');
export const CI_USER_LABEL = s__('MlExperimentTracking|Triggered by');
export const CI_MR_LABEL = __('Merge request');
