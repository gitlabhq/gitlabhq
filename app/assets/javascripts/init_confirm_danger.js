import Vue from 'vue';
import { pickBy } from 'lodash';
import { parseBoolean } from './lib/utils/common_utils';
import ConfirmDanger from './vue_shared/components/confirm_danger/confirm_danger.vue';

export default () => {
  const el = document.querySelector('.js-confirm-danger');
  if (!el) return null;

  const {
    removeFormId = null,
    phrase,
    buttonText,
    buttonClass = '',
    buttonTestid,
    buttonVariant,
    confirmDangerMessage,
    confirmButtonText = null,
    disabled,
    additionalInformation,
    htmlConfirmationMessage,
  } = el.dataset;

  return new Vue({
    el,
    provide: pickBy(
      {
        htmlConfirmationMessage,
        confirmDangerMessage,
        additionalInformation,
        confirmButtonText,
      },
      (v) => Boolean(v),
    ),
    render: (createElement) =>
      createElement(ConfirmDanger, {
        props: {
          phrase,
          buttonText,
          buttonClass,
          buttonVariant,
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
