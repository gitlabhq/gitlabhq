import Vue from 'vue';
import initUserInternalRegexPlaceholder from '../account_and_limits';
import IntegrationHelpText from '~/vue_shared/components/integrations_help_text.vue';

document.addEventListener('DOMContentLoaded', () => {
  initUserInternalRegexPlaceholder();

  const gitpodSettingEl = document.querySelector('#js-gitpod-settings-help-text');
  if (!gitpodSettingEl) {
    return;
  }

  // eslint-disable-next-line no-new
  new Vue({
    el: gitpodSettingEl,
    name: 'GitpodSettings',
    components: {
      IntegrationHelpText,
    },
  });
});
