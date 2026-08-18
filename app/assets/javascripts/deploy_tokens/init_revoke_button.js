import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import RevokeButton from './components/revoke_button.vue';

export default () => {
  const containers = document.querySelectorAll('.js-deploy-token-revoke-button');

  if (!containers.length) {
    return false;
  }

  return containers.forEach((el) => {
    const { token, revokePath } = el.dataset;

    return initVueApp({
      el,
      name: 'RevokeButtonRoot',
      provide: {
        token: JSON.parse(token),
        revokePath,
      },
      component: RevokeButton,
    });
  });
};
