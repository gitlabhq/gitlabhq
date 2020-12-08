import Vue from 'vue';
import { updateHistory, removeParams } from '~/lib/utils/url_utility';
import RecoveryCodes from './components/recovery_codes.vue';
import { SUCCESS_QUERY_PARAM } from './constants';

export const initRecoveryCodes = () => {
  const el = document.querySelector('.js-2fa-recovery-codes');

  if (!el) {
    return false;
  }

  const { codes = '[]', profileAccountPath = '' } = el.dataset;

  return new Vue({
    el,
    render(createElement) {
      return createElement(RecoveryCodes, {
        props: {
          codes: JSON.parse(codes),
          profileAccountPath,
        },
      });
    },
  });
};

export const initClose2faSuccessMessage = () => {
  const closeButton = document.querySelector('.js-close-2fa-enabled-success-alert');

  if (!closeButton) {
    return;
  }

  closeButton.addEventListener(
    'click',
    () => {
      updateHistory({
        url: removeParams([SUCCESS_QUERY_PARAM]),
        title: document.title,
        replace: true,
      });
    },
    { once: true },
  );
};
