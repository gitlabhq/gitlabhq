import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import WebIdeOAuthApplicationCallout from './components/oauth_application_callout.vue';

export const initWebIdeOAuthApplicationCallout = () => {
  const el = document.querySelector('#web_ide_oauth_application_callout');

  if (!el) {
    return null;
  }

  const { redirectUrlPath, resetApplicationSettingsPath } = el.dataset;

  return initVueApp({
    el,
    name: 'WebIdeOAuthApplicationCallout',
    component: WebIdeOAuthApplicationCallout,
    props: {
      redirectUrlPath,
      resetApplicationSettingsPath,
    },
  });
};
