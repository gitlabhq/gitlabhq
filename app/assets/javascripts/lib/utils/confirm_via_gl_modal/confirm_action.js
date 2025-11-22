import Vue from 'vue';
import { InternalEvents } from '~/tracking';

/**
 * Factory function that creates a confirmAction function with custom mount and destroy callbacks.
 * This is useful for dependency injection, particularly in testing scenarios where you need
 * to control how the confirmation modal is mounted and destroyed.
 *
 * @example
 * // Create a custom confirmAction for testing
 * import { createConfirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_action';
 *
 * const confirmAction = createConfirmAction({
 *   mountFn: (Component) => shallowMount(Component),
 *   destroyFn: (instance) => instance.destroy(),
 * });
 *
 * @param {object} options - Configuration options
 * @param {Function} options.mountFn - Function to mount the confirmation modal component.
 *   Receives a Vue component definition and should return an instance (e.g., Vue or VueWrapper instance)
 * @param {Function} options.destroyFn - Function to destroy the mounted modal instance.
 *   Receives the instance returned by mountFn.
 * @returns {Function} A confirmAction function with the signature (message, options) => Promise<boolean>
 */
export function createConfirmAction({ mountFn, destroyFn }) {
  return function confirmAction(
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

      const ConfirmAction = {
        name: 'ConfirmActionRoot',
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
                  destroyFn(component);
                  component = undefined;
                  resolve(confirmed);
                },
              },
            },
            [message],
          );
        },
      };

      component = mountFn(ConfirmAction);
    });
  };
}

/**
 * Displays a confirmation modal and returns a promise that resolves based on user action.
 *
 * @example
 * // Basic confirmation
 * const confirmed = await confirmAction('Are you sure you want to delete this item?');
 * if (confirmed) {
 *   // User clicked the primary button
 *   deleteItem();
 * }
 *
 * @example
 * // Confirmation with custom buttons
 * const confirmed = await confirmAction('Delete this branch?', {
 *   primaryBtnText: 'Delete',
 *   primaryBtnVariant: 'danger',
 *   title: 'Confirm deletion',
 * });
 *
 * @example
 * // Confirmation with tracking
 * const confirmed = await confirmAction('Unprotect this branch?', {
 *   primaryBtnText: 'Unprotect',
 *   primaryBtnVariant: 'danger',
 *   trackingEvent: {
 *     name: 'unprotect_branch',
 *     label: 'repository_settings',
 *   },
 * });
 *
 * @param {string} message - The confirmation message to display in the modal body.
 *   This is rendered as plain text unless modalHtmlMessage is provided.
 * @param {object} [options={}] - Configuration options for the confirmation modal
 * @param {string} [options.primaryBtnVariant] - Variant for the primary (confirm) button.
 *   Common values: 'confirm', 'danger', 'info', 'success'
 * @param {string} [options.primaryBtnText] - Text for the primary (confirm) button
 * @param {string} [options.secondaryBtnVariant] - Variant for the secondary button
 * @param {string} [options.secondaryBtnText] - Text for the secondary button.
 *   If not provided, no secondary button is shown.
 * @param {string} [options.cancelBtnVariant] - Variant for the cancel button
 * @param {string} [options.cancelBtnText] - Text for the cancel button
 * @param {string} [options.modalHtmlMessage] - HTML message to display instead of the plain text message.
 *   When provided, this takes precedence over the message parameter.
 * @param {string} [options.title] - Title text for the modal header.
 *   If not provided, the modal header is hidden.
 * @param {boolean} [options.hideCancel=false] - Whether to hide the cancel button
 * @param {string} [options.size] - Size of the modal. Common values: 'sm', 'md', 'lg'
 * @param {object} [options.trackingEvent] - Optional tracking event to fire when user confirms
 * @param {string} [options.trackingEvent.name] - Name of the tracking event
 * @param {string} [options.trackingEvent.label] - Label for the tracking event
 * @param {string} [options.trackingEvent.property] - Property for the tracking event
 * @param {*} [options.trackingEvent.value] - Value for the tracking event
 * @returns {Promise<boolean>} A promise that resolves to `true` if the user clicked the primary button,
 *   or `false` if the user cancelled or closed the modal
 */
export const confirmAction = createConfirmAction({
  mountFn(Component) {
    return new Vue(Component).$mount();
  },
  destroyFn(instance) {
    instance.$destroy();
  },
});
