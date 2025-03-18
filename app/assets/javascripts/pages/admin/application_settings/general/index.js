import { initSilentModeSettings } from '~/silent_mode_settings';
import { initSimpleApp } from '~/helpers/init_simple_app_helper';
import VscodeExtensionMarketplaceSettings from '~/vscode_extension_marketplace/components/settings_app.vue';
import initAccountAndLimitsSection from '../account_and_limits';
import initGitpod from '../gitpod';
import initSignupRestrictions from '../signup_restrictions';

(() => {
  initAccountAndLimitsSection();
  initGitpod();
  initSignupRestrictions();
  initSilentModeSettings();

  initSimpleApp('#js-extension-marketplace-settings-app', VscodeExtensionMarketplaceSettings);
})();
