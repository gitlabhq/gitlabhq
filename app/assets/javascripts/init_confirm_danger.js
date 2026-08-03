import { pickBy } from 'lodash-es';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
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

    return initVueApp({
      el: element,
      name: 'ConfirmDangerRoot',
      provide: pickBy(
        {
          htmlConfirmationMessage,
          confirmDangerMessage,
          additionalInformation,
          confirmButtonText,
        },
        (v) => Boolean(v),
      ),
      component: ConfirmDanger,
      props: {
        phrase,
        buttonText,
        buttonClass,
        buttonVariant,
        buttonTestid,
        disabled: parseBoolean(disabled),
      },
      events: {
        confirm: () => {
          if (removeFormId) document.getElementById(removeFormId)?.submit();
        },
      },
    });
  });
};
