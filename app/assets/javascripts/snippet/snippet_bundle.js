import { initEditorLite } from '~/blob/utils';
import setupCollapsibleInputs from './collapsible_input';

let editor;

const initAce = () => {
  const editorEl = document.getElementById('editor');
  const form = document.querySelector('.snippet-form-holder form');
  const content = document.querySelector('.snippet-file-content');

  editor = initEditorLite({ el: editorEl });

  form.addEventListener('submit', () => {
    content.value = editor.getValue();
  });
};

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

export const initEditor = () => {
  if (window?.gon?.features?.monacoSnippets) {
    initMonaco();
  } else {
    initAce();
  }
  setupCollapsibleInputs();
};

export default () => {
  initEditor();
};
