import Vue from 'vue';
import WebIdeOAuthApplicationCallout from './components/oauth_application_callout.vue';

export const initWebIdeOAuthApplicationCallout = () => {
  const el = document.querySelector('#web_ide_oauth_application_callout');

  if (!el) {
    return null;
  }

  const { redirectUrlPath, resetApplicationSettingsPath } = el.dataset;

  return new Vue({
    el,
    name: 'WebIdeOAuthApplicationCallout',
    render(h) {
      return h(WebIdeOAuthApplicationCallout, {
        props: {
          redirectUrlPath,
          resetApplicationSettingsPath,
        },
      });
    },
  });
};
