import { initWebBasedCommitSigningSettings } from '~/vue_shared/components/web_based_commit_signing/init_settings';

export const initWebBasedCommitSigningProjectSettings = () => {
  const el = document.getElementById('js-web-based-commit-signing-settings-project');

  if (!el) return false;

  return initWebBasedCommitSigningSettings(el, el.dataset, false);
};
