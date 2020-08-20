import Editor from '~/editor/editor_lite';

export function initEditorLite({ el, ...args }) {
  if (!el) {
    throw new Error(`"el" parameter is required to initialize Editor`);
  }
  const editor = new Editor({
    scrollbar: {
      alwaysConsumeMouseWheel: false,
    },
  });
  editor.createInstance({
    el,
    ...args,
  });

  return editor;
}

export default () => ({});
