import { IMAGE_FORMATS } from './constants';

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

export const getFilename = (file) => {
  let fileName;
  if (file) {
    fileName = file.name;
  }

  return fileName;
};

export const validateImageName = (file) => {
  const fileName = file.name ? file.name : 'image.png';
  return IMAGE_FORMATS.test(fileName) ? fileName : 'image.png';
};

export const validateFileFromAllowList = (fileName, allowList) => {
  const parts = fileName.split('.');
  const ext = `.${parts[parts.length - 1]}`.toLowerCase();

  return allowList.map((fileExt) => fileExt.toLowerCase()).includes(ext);
};
