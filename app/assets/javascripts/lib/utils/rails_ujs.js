import Rails from '@rails/ujs';
import { confirmViaGlModal } from './confirm_via_gl_modal/confirm_via_gl_modal';
import { ignoreWhilePending } from './ignore_while_pending';

function monkeyPatchConfirmModal() {
  /**
   * This function is used to replace the `Rails.confirm` which uses `window.confirm`
   *
   * This function opens a confirmation modal which will resolve in a promise.
   * Because the `Rails.confirm` API is synchronous, we go with a little hack here:
   *
   * 1. User clicks on something with `data-confirm`
   * 2. We open the modal and return `false`, ending the "Rails" event chain
   * 3. If the modal is closed and the user "confirmed" the action
   *     1. replace the `Rails.confirm` with a function that always returns `true`
   *     2. click the same element programmatically
   *
   * @param message {String} Message to be shown in the modal
   * @param element {HTMLElement} Element that was clicked on
   * @returns {boolean}
   */
  const safeConfirm = ignoreWhilePending(confirmViaGlModal);

  function confirmViaModal(message, element) {
    safeConfirm(message, element)
      .then((confirmed) => {
        if (confirmed) {
          Rails.confirm = () => true;
          element.click();
          Rails.confirm = confirmViaModal;
        }
      })
      .catch(() => {});
    return false;
  }

  Rails.confirm = confirmViaModal;
}

monkeyPatchConfirmModal();

export const initRails = () => {
  // eslint-disable-next-line no-underscore-dangle
  if (!window._rails_loaded) {
    Rails.start();

    // Count XHR requests for tests. See spec/support/helpers/wait_for_requests.rb
    window.pendingRailsUJSRequests = 0;
    document.body.addEventListener('ajax:complete', () => {
      window.pendingRailsUJSRequests -= 1;
    });

    document.body.addEventListener('ajax:beforeSend', () => {
      window.pendingRailsUJSRequests += 1;
    });
  }
};

export { Rails };
