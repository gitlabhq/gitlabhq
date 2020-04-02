export default (buttonSelector, fileSelector) => {
  const btn = document.querySelector(buttonSelector);
  const fileInput = document.querySelector(fileSelector);

  if (!btn || !fileInput) return;

  const form = btn.closest('form');

  btn.addEventListener('click', () => {
    fileInput.click();
  });

  fileInput.addEventListener('change', () => {
    form.querySelector('.js-filename').textContent = fileInput.value.replace(/^.*[\\\/]/, ''); // eslint-disable-line no-useless-escape
  });
};

export const getFilename = ({ clipboardData }) => {
  let value;
  if (window.clipboardData && window.clipboardData.getData) {
    value = window.clipboardData.getData('Text');
  } else if (clipboardData && clipboardData.getData) {
    value = clipboardData.getData('text/plain');
  }
  value = value.split('\r');
  return value[0];
};
