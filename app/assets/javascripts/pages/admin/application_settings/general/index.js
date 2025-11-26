import { initSilentModeSettings } from '~/silent_mode_settings';
import { initSimpleApp } from '~/helpers/init_simple_app_helper';
import VscodeExtensionMarketplaceSettings from '~/vscode_extension_marketplace/components/settings_app.vue';
import { initAdminDeletionProtectionSettings } from '~/admin/application_settings/deletion_protection';
import initAccountAndLimitsSection from '../account_and_limits';
import initGitpod from '../gitpod';
import initSignupRestrictions from '../signup_restrictions';
import initIframeSettings from '../iframe';

(() => {
  initAccountAndLimitsSection();
  initGitpod();
  initSignupRestrictions();
  initSilentModeSettings();
  initAdminDeletionProtectionSettings();
  initIframeSettings();

  initSimpleApp('#js-extension-marketplace-settings-app', VscodeExtensionMarketplaceSettings);
})();
