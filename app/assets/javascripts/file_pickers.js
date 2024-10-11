export default function initFilePickers() {
  const filePickers = document.querySelectorAll('.js-filepicker');

  filePickers.forEach((filePicker) => {
    const maxFileSize = filePicker.dataset.maxFileSize || null;
    const button = filePicker.querySelector('.js-filepicker-button');
    const error = filePicker.querySelector('.js-filepicker-error');

    button.addEventListener('click', () => {
      const form = button.closest('form');
      form.querySelector('.js-filepicker-input').click();
    });

    const input = filePicker.querySelector('.js-filepicker-input');

    input.addEventListener('change', () => {
      const form = input.closest('form');
      const filename = input.files[0].name.replace(/^.*[\\\/]/, ''); // eslint-disable-line no-useless-escape

      // Validate file size
      if (maxFileSize && input.files[0].size / 1024 > maxFileSize) {
        // On error
        button.classList.add('btn-danger', 'btn-danger-secondary');
        error.classList.add('!gl-block');

        // Clear file input field
        // to prevent upload and ability to save
        form.querySelector('.js-filepicker-input').value = '';
      } else {
        // No error
        button.classList.remove('btn-danger', 'btn-danger-secondary');
        error.classList.remove('!gl-block');
      }

      form.querySelector('.js-filepicker-filename').textContent = filename;
    });
  });
}
