export default function initFilePickers() {
  const filePickers = document.querySelectorAll('.js-filepicker');

  filePickers.forEach(filePicker => {
    const button = filePicker.querySelector('.js-filepicker-button');

    button.addEventListener('click', () => {
      const form = button.closest('form');
      form.querySelector('.js-filepicker-input').click();
    });

    const input = filePicker.querySelector('.js-filepicker-input');

    input.addEventListener('change', () => {
      const form = input.closest('form');
      const filename = input.value.replace(/^.*[\\\/]/, ''); // eslint-disable-line no-useless-escape

      form.querySelector('.js-filepicker-filename').textContent = filename;
    });
  });
}
