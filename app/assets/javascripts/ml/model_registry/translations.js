import { s__, n__ } from '~/locale';

export const MODEL_DETAILS_TAB_LABEL = s__('MlModelRegistry|Details');
export const MODEL_OTHER_VERSIONS_TAB_LABEL = s__('MlModelRegistry|Versions');
export const MODEL_CANDIDATES_TAB_LABEL = s__('MlModelRegistry|Version candidates');
export const LATEST_VERSION_LABEL = s__('MlModelRegistry|Latest version');
export const NO_VERSIONS_LABEL = s__('MlModelRegistry|This model has no versions');

export const versionsCountLabel = (versionCount) =>
  n__('MlModelRegistry|%d version', 'MlModelRegistry|%d versions', versionCount);
