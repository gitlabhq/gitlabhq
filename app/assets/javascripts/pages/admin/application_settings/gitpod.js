import Vue from 'vue';
import IntegrationHelpText from '~/vue_shared/components/integrations_help_text.vue';

export default function initGitpod() {
  const el = document.querySelector('#js-gitpod-settings-help-text');

  if (!el) {
    return false;
  }

  const { message, messageUrl } = el.dataset;

  return new Vue({
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
}
