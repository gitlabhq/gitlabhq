import Vue from 'vue';
import ConfirmDanger from './vue_shared/components/confirm_danger/confirm_danger.vue';

export default () => {
  const el = document.querySelector('.js-confirm-danger');
  if (!el) return null;

  const { phrase, buttonText, confirmDangerMessage } = el.dataset;

  return new Vue({
    el,
    render: (createElement) =>
      createElement(ConfirmDanger, {
        props: {
          phrase,
          buttonText,
        },
        provide: {
          confirmDangerMessage,
        },
      }),
  });
};
