import { initWebBasedCommitSigningSettings as initFactory } from '~/vue_shared/components/web_based_commit_signing/init_settings';

export const initWebBasedCommitSigningSettings = () => {
  const el = document.getElementById('js-web-based-commit-signing-settings');

  if (!el) return false;

  return initFactory(el, el.dataset, true);
};
