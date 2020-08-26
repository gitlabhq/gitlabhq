import Editor from '~/editor/editor_lite';

export function initEditorLite({ el, ...args }) {
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
