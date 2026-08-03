import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import IntegrationHelpText from '~/vue_shared/components/integrations_help_text.vue';

export default function initGitpod() {
  const el = document.querySelector('#js-gitpod-settings-help-text');

  if (!el) {
    return false;
  }

  const { message, messageUrl } = el.dataset;

  return initVueApp({
    el,
    name: 'GitpodIntegrationHelpTextRoot',
    component: IntegrationHelpText,
    props: {
      message,
      messageUrl,
    },
  });
}
