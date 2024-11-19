import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import { updateHistory, removeParams } from '~/lib/utils/url_utility';
import RecoveryCodes from './components/recovery_codes.vue';
import TwoFactorActionConfirm from './components/two_factor_action_confirm.vue';
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

export const initTwoFactorConfirm = () => {
  document.querySelectorAll('.js-two-factor-action-confirm').forEach((el) => {
    const { buttonText, classes, icon, message, method, passwordRequired, path, title, variant } =
      el.dataset;

    // eslint-disable-next-line no-new
    new Vue({
      el,
      render(createElement) {
        return createElement(TwoFactorActionConfirm, {
          props: {
            buttonText,
            classes,
            icon,
            message,
            method,
            passwordRequired: parseBoolean(passwordRequired),
            path,
            title,
            variant,
          },
        });
      },
    });
  });
};
