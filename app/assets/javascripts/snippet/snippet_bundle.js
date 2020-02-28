/* global ace */
import Editor from '~/editor/editor_lite';
import setupCollapsibleInputs from './collapsible_input';

let editor;

const initAce = () => {
  editor = ace.edit('editor');

  const form = document.querySelector('.snippet-form-holder form');
  const content = document.querySelector('.snippet-file-content');
  form.addEventListener('submit', () => {
    content.value = editor.getValue();
  });
};

const initMonaco = () => {
  const editorEl = document.getElementById('editor');
  const contentEl = document.querySelector('.snippet-file-content');
  const fileNameEl = document.querySelector('.snippet-file-name');
  const form = document.querySelector('.snippet-form-holder form');

  editor = new Editor();
  editor.createInstance({
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
