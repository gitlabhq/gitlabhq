import { initEditorLite } from '~/blob/utils';
import setupCollapsibleInputs from './collapsible_input';

let editor;

const initMonaco = () => {
  const editorEl = document.getElementById('editor');
  const contentEl = document.querySelector('.snippet-file-content');
  const fileNameEl = document.querySelector('.js-snippet-file-name');
  const form = document.querySelector('.snippet-form-holder form');

  editor = initEditorLite({
    el: editorEl,
    blobPath: fileNameEl.value,
    blobContent: contentEl.value,
  });

  fileNameEl.addEventListener('change', () => {
    editor.updateModelLanguage(fileNameEl.value);
  });

  form.addEventListener('submit', () => {
    contentEl.value = editor.getValue();
  });
};

export default () => {
  initMonaco();
  setupCollapsibleInputs();
};
