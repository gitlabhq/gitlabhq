export const initPersonalAccessTokenFormValidation = () => {
  const patField = document.querySelector('.js-import-github-pat-field');
  const patValidation = document.querySelector('.js-import-github-pat-validation');
  const authenticateButton = document.querySelector('.js-import-github-pat-authenticate');

  const removeError = () => {
    patField.classList.remove('is-invalid');
    patValidation.classList.remove('!gl-block');
  };

  authenticateButton.addEventListener('click', (e) => {
    if (patField.value === '') {
      e.preventDefault();
      patField.classList.add('is-invalid');
      patValidation.classList.add('!gl-block');
    }
  });

  patField.addEventListener('input', () => {
    removeError();
  });
};
