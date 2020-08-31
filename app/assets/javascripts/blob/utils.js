import Editor from '~/editor/editor_lite';

export function initEditorLite({ el, ...args }) {
  const editor = new Editor({
    scrollbar: {
      alwaysConsumeMouseWheel: false,
    },
  });

  return editor.createInstance({
    el,
    ...args,
  });
}

export default () => ({});
