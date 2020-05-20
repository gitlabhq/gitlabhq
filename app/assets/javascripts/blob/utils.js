import Editor from '~/editor/editor_lite';

export function initEditorLite({ el, blobPath, blobContent }) {
  if (!el) {
    throw new Error(`"el" parameter is required to initialize Editor`);
  }
  const editor = new Editor();
  editor.createInstance({
    el,
    blobPath,
    blobContent,
  });

  return editor;
}

export default () => ({});
