/* global ace */
import Editor from '~/editor/editor_lite';

export function initEditorLite({ el, blobPath, blobContent }) {
  if (!el) {
    throw new Error(`"el" parameter is required to initialize Editor`);
  }
  let editor;

  if (window?.gon?.features?.monacoSnippets) {
    editor = new Editor();
    editor.createInstance({
      el,
      blobPath,
      blobContent,
    });
  } else {
    editor = ace.edit(el);
  }

  return editor;
}

export default () => ({});
