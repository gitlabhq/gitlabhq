import Vue from 'vue';
import OAuthSecret from './components/oauth_secret.vue';

export const initOAuthApplicationSecret = () => {
  const el = document.querySelector('#js-oauth-application-secret');

  if (!el) {
    return null;
  }

  const { initialSecret, renewPath } = el.dataset;

  return new Vue({
    el,
    name: 'OAuthSecretRoot',
    provide: { initialSecret, renewPath },
    render(h) {
      return h(OAuthSecret);
    },
  });
};
