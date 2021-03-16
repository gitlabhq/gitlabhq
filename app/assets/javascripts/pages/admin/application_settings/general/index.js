import Vue from 'vue';
import IntegrationHelpText from '~/vue_shared/components/integrations_help_text.vue';
import initUserInternalRegexPlaceholder from '../account_and_limits';

(() => {
  initUserInternalRegexPlaceholder();

  const el = document.querySelector('#js-gitpod-settings-help-text');
  if (!el) {
    return;
  }

  const { message, messageUrl } = el.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    render(createElement) {
      return createElement(IntegrationHelpText, {
        props: {
          message,
          messageUrl,
        },
      });
    },
  });
})();
