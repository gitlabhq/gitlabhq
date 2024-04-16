import initConfirmModal from '~/confirm_modal';
import AddSshKeyValidation from '~/profile/add_ssh_key_validation';
import { initExpiresAtField } from '~/access_tokens/index';

initConfirmModal();

function initSshKeyValidation() {
  const input = document.querySelector('.js-add-ssh-key-validation-input');
  if (!input) return;

  const supportedAlgorithms = JSON.parse(input.dataset.supportedAlgorithms);
  const warning = document.querySelector('.js-add-ssh-key-validation-warning');
  const originalSubmit = input.form.querySelector('.js-add-ssh-key-validation-original-submit');
  const confirmSubmit = warning.querySelector('.js-add-ssh-key-validation-confirm-submit');
  const cancelButton = input.form.querySelector('.js-add-ssh-key-validation-cancel');

  const addSshKeyValidation = new AddSshKeyValidation(
    supportedAlgorithms,
    input,
    warning,
    originalSubmit,
    confirmSubmit,
    cancelButton,
  );
  addSshKeyValidation.register();
}

initSshKeyValidation();

initExpiresAtField();

document.getElementById('key_key').addEventListener('input', (event) => {
  const keyTitleField = document.getElementById('key_title');

  const match = event.target.value.match(/^\S+ \S+ (.+)\n?$/);

  if (match && match.length > 1) {
    const [, title] = match;
    keyTitleField.value = title;
    keyTitleField.dispatchEvent(new Event('change'));
  }
});
