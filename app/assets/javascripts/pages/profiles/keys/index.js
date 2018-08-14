import AddSshKeyValidation from '~/profile/add_ssh_key_validation';

document.addEventListener('DOMContentLoaded', () => {
  const input = document.querySelector('.js-add-ssh-key-validation-input');
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
});
