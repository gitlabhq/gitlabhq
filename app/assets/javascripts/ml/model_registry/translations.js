import { __, s__, n__, sprintf } from '~/locale';

export const MODEL_DETAILS_TAB_LABEL = s__('MlModelRegistry|Details');
export const MODEL_OTHER_VERSIONS_TAB_LABEL = s__('MlModelRegistry|Versions');
export const MODEL_CANDIDATES_TAB_LABEL = s__('MlModelRegistry|Version candidates');
export const LATEST_VERSION_LABEL = s__('MlModelRegistry|Latest version');

export const versionsCountLabel = (versionCount) =>
  n__('MlModelRegistry|%d version', 'MlModelRegistry|%d versions', versionCount);

export const TITLE_LABEL = s__('MlModelRegistry|Model registry');

export const modelsCountLabel = (modelCount) =>
  n__('MlModelRegistry|%d model', 'MlModelRegistry|%d models', modelCount);

export const DESCRIPTION_LABEL = __('Description');
export const NO_DESCRIPTION_PROVIDED_LABEL = s__('MlModelRegistry|No description provided');
export const INFO_LABEL = s__('MlModelRegistry|Info');
export const ID_LABEL = s__('MlModelRegistry|ID');
export const MLFLOW_ID_LABEL = s__('MlModelRegistry|MLflow run ID');
export const STATUS_LABEL = s__('MlModelRegistry|Status');
export const EXPERIMENT_LABEL = s__('MlModelRegistry|Experiment');
export const ARTIFACTS_LABEL = s__('MlModelRegistry|Artifacts');
export const PARAMETERS_LABEL = s__('MlModelRegistry|Parameters');
export const PERFORMANCE_LABEL = s__('MlModelRegistry|Model performance');
export const METADATA_LABEL = s__('MlModelRegistry|Metadata');
export const NO_PARAMETERS_MESSAGE = s__('MlModelRegistry|No logged parameters');
export const NO_METRICS_MESSAGE = s__('MlModelRegistry|No logged metrics');
export const NO_METADATA_MESSAGE = s__('MlModelRegistry|No logged metadata');
export const NO_CI_MESSAGE = s__('MlModelRegistry|Candidate not linked to a CI build');
export const CI_SECTION_LABEL = s__('MlModelRegistry|CI Info');
export const JOB_LABEL = __('Job');
export const CI_USER_LABEL = s__('MlModelRegistry|Triggered by');
export const CI_MR_LABEL = __('Merge request');

export const makeLoadVersionsErrorMessage = (message) =>
  sprintf(s__('MlModelRegistry|Failed to load model versions with error: %{message}'), {
    message,
  });

export const NO_CANDIDATES_LABEL = s__('MlModelRegistry|This model has no candidates');
export const makeLoadCandidatesErrorMessage = (message) =>
  sprintf(s__('MlModelRegistry|Failed to load model candidates with error: %{message}'), {
    message,
  });
