import Vue from 'vue';
import { InternalEvents } from '~/tracking';

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
    size,
    trackingEvent,
  } = {},
) {
  return new Promise((resolve) => {
    let confirmed = false;
    let component;

    const ConfirmAction = Vue.extend({
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
              size,
            },
            on: {
              confirmed() {
                confirmed = true;
                if (trackingEvent) {
                  InternalEvents.trackEvent(trackingEvent.name, {
                    label: trackingEvent.label,
                    property: trackingEvent.property,
                    value: trackingEvent.value,
                  });
                }
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
    });

    component = new ConfirmAction().$mount();
  });
}
