import Vue from 'vue';

export function confirmAction(
  message,
  {
    primaryBtnVariant,
    primaryBtnText,
    secondaryBtnVariant,
    secondaryBtnText,
    cancelBtnVariant,
    cancelBtnText,
    modalHtmlMessage,
    title,
    hideCancel,
  } = {},
) {
  return new Promise((resolve) => {
    let confirmed = false;

    const component = new Vue({
      components: {
        ConfirmModal: () => import('./confirm_modal.vue'),
      },
      render(h) {
        return h(
          'confirm-modal',
          {
            props: {
              secondaryText: secondaryBtnText,
              secondaryVariant: secondaryBtnVariant,
              primaryVariant: primaryBtnVariant,
              primaryText: primaryBtnText,
              cancelVariant: cancelBtnVariant,
              cancelText: cancelBtnText,
              title,
              modalHtmlMessage,
              hideCancel,
            },
            on: {
              confirmed() {
                confirmed = true;
              },
              closed() {
                component.$destroy();
                resolve(confirmed);
              },
            },
          },
          [message],
        );
      },
    }).$mount();
  });
}

export function confirmViaGlModal(message, element) {
  const primaryBtnConfig = {};

  const { confirmBtnVariant } = element.dataset;

  if (confirmBtnVariant) {
    primaryBtnConfig.primaryBtnVariant = confirmBtnVariant;
  }

  const screenReaderText =
    element.querySelector('.gl-sr-only')?.textContent ||
    element.querySelector('.sr-only')?.textContent ||
    element.getAttribute('aria-label');

  if (screenReaderText) {
    primaryBtnConfig.primaryBtnText = screenReaderText;
  }

  return confirmAction(message, primaryBtnConfig);
}
