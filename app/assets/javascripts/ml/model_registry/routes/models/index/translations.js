import { s__, n__, sprintf } from '~/locale';

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
