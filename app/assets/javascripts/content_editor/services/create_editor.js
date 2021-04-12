import { isFunction, isString } from 'lodash';
import { Editor } from 'tiptap';
import { Bold, Code } from 'tiptap-extensions';
import { PROVIDE_SERIALIZER_OR_RENDERER_ERROR } from '../constants';
import createMarkdownSerializer from './markdown_serializer';

const createEditor = async ({ content, renderMarkdown, serializer: customSerializer } = {}) => {
  if (!customSerializer && !isFunction(renderMarkdown)) {
    throw new Error(PROVIDE_SERIALIZER_OR_RENDERER_ERROR);
  }

  const editor = new Editor({
    extensions: [new Bold(), new Code()],
  });
  const serializer = customSerializer || createMarkdownSerializer({ render: renderMarkdown });

  editor.setSerializedContent = async (serializedContent) => {
    editor.setContent(
      await serializer.deserialize({ schema: editor.schema, content: serializedContent }),
    );
  };

  editor.getSerializedContent = () => {
    return serializer.serialize({ schema: editor.schema, content: editor.getJSON() });
  };

  if (isString(content)) {
    await editor.setSerializedContent(content);
  }

  return editor;
};

export default createEditor;
