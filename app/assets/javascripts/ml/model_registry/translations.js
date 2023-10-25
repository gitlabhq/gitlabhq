import { s__, n__, sprintf } from '~/locale';

export const MODEL_DETAILS_TAB_LABEL = s__('MlModelRegistry|Details');
export const MODEL_OTHER_VERSIONS_TAB_LABEL = s__('MlModelRegistry|Versions');
export const MODEL_CANDIDATES_TAB_LABEL = s__('MlModelRegistry|Version candidates');
export const LATEST_VERSION_LABEL = s__('MlModelRegistry|Latest version');
export const NO_VERSIONS_LABEL = s__('MlModelRegistry|This model has no versions');

export const versionsCountLabel = (versionCount) =>
  n__('MlModelRegistry|%d version', 'MlModelRegistry|%d versions', versionCount);

export const TITLE_LABEL = s__('MlModelRegistry|Model registry');
export const NO_MODELS_LABEL = s__('MlModelRegistry|No models registered in this project');

export const modelVersionCountMessage = (version, versionCount) => {
  if (!versionCount) return s__('MlModelRegistry|No registered versions');

  const message = n__(
    'MlModelRegistry|%{version} · No other versions',
    'MlModelRegistry|%{version} · %{versionCount} versions',
    versionCount,
  );

  return sprintf(message, { version, versionCount });
};
