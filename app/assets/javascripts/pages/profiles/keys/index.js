import initConfirmModal from '~/confirm_modal';
import AddSshKeyValidation from '~/profile/add_ssh_key_validation';

initConfirmModal();

function initSshKeyValidation() {
  const input = document.querySelector('.js-add-ssh-key-validation-input');
  if (!input) return;

  const warning = document.querySelector('.js-add-ssh-key-validation-warning');
  const originalSubmit = input.form.querySelector('.js-add-ssh-key-validation-original-submit');
  const confirmSubmit = warning.querySelector('.js-add-ssh-key-validation-confirm-submit');

  const addSshKeyValidation = new AddSshKeyValidation(
    input,
    warning,
    originalSubmit,
    confirmSubmit,
  );
  addSshKeyValidation.register();
}

initSshKeyValidation();
