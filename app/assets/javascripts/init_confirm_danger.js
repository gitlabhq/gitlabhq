import Vue from 'vue';
import { pickBy } from 'lodash';
import { parseBoolean } from './lib/utils/common_utils';
import ConfirmDanger from './vue_shared/components/confirm_danger/confirm_danger.vue';

export default () => {
  const elements = document.querySelectorAll('.js-confirm-danger');

  if (!elements.length) return;

  elements.forEach((element) => {
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
    } = element.dataset;

    return new Vue({
      el: element,
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
  });
};
