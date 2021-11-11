import Vue from 'vue';

export function confirmViaGlModal(message, element) {
  return new Promise((resolve) => {
    let confirmed = false;

    const props = {};

    const confirmBtnVariant = element.getAttribute('data-confirm-btn-variant');

    if (confirmBtnVariant) {
      props.primaryVariant = confirmBtnVariant;
    }
    const screenReaderText =
      element.querySelector('.gl-sr-only')?.textContent ||
      element.querySelector('.sr-only')?.textContent ||
      element.getAttribute('aria-label');

    if (screenReaderText) {
      props.primaryText = screenReaderText;
    }

    const component = new Vue({
      components: {
        ConfirmModal: () => import('./confirm_modal.vue'),
      },
      render(h) {
        return h(
          'confirm-modal',
          {
            props,
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
