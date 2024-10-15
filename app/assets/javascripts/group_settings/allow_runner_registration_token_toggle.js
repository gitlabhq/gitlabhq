import axios from 'axios';
import { initToggle } from '~/toggles';
import toast from '~/vue_shared/plugins/global_toast';
import {
  I18N_PENDING_MESSAGE,
  I18N_SUCCESS_MESSAGE,
  I18N_UNDO_ACTION_TEXT,
  I18N_RETRY_ACTION_TEXT,
  I18N_ERROR_MESSAGE,
} from './constants';

export const initAllowRunnerRegistrationTokenToggle = () => {
  const toggle = () => {
    const toggleButton = document.querySelector(
      '.js-allow-runner-registration-token-toggle button',
    );

    toggleButton.click();
  };

  let toastMessage = {};
  const displayToast = (message, options = {}) => {
    toastMessage.hide?.();
    toastMessage = toast(message, options);
  };

  const el = document.querySelector('.js-allow-runner-registration-token-toggle');
  const input = document.querySelector('.js-allow-runner-registration-token-input');

  if (el && input) {
    const form = el.closest('form');
    const toggleElement = initToggle(el);

    toggleElement.$on('change', async (isEnabled) => {
      if (toggleElement.isLoading) return;

      try {
        toggleElement.isLoading = true;
        input.value = isEnabled;

        displayToast(I18N_PENDING_MESSAGE);

        await axios.post(form.action, new FormData(form));

        displayToast(I18N_SUCCESS_MESSAGE, {
          action: {
            text: I18N_UNDO_ACTION_TEXT,
            onClick: toggle,
          },
        });
      } catch (_) {
        input.value = !isEnabled;
        toggleElement.value = !isEnabled;

        displayToast(I18N_ERROR_MESSAGE, {
          action: {
            text: I18N_RETRY_ACTION_TEXT,
            onClick: toggle,
          },
        });
      } finally {
        toggleElement.isLoading = false;
      }
    });

    return toggleElement;
  }

  return null;
};
