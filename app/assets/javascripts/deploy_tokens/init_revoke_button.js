import Vue from 'vue';
import RevokeButton from './components/revoke_button.vue';

export default () => {
  const containers = document.querySelectorAll('.js-deploy-token-revoke-button');

  if (!containers.length) {
    return false;
  }

  return containers.forEach((el) => {
    const { token, revokePath } = el.dataset;

    return new Vue({
      el,
      provide: {
        token: JSON.parse(token),
        revokePath,
      },
      render(h) {
        return h(RevokeButton);
      },
    });
  });
};
