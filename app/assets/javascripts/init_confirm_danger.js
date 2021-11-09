import Vue from 'vue';
import { parseBoolean } from './lib/utils/common_utils';
import ConfirmDanger from './vue_shared/components/confirm_danger/confirm_danger.vue';

export default () => {
  const el = document.querySelector('.js-confirm-danger');
  if (!el) return null;

  const {
    removeFormId = null,
    phrase,
    buttonText,
    buttonTestid = null,
    confirmDangerMessage,
    disabled = false,
  } = el.dataset;

  return new Vue({
    el,
    provide: {
      confirmDangerMessage,
    },
    render: (createElement) =>
      createElement(ConfirmDanger, {
        props: {
          phrase,
          buttonText,
          buttonTestid,
          disabled: parseBoolean(disabled),
        },
        on: {
          confirm: () => {
            if (removeFormId) document.getElementById(removeFormId)?.submit();
          },
        },
      }),
  });
};
