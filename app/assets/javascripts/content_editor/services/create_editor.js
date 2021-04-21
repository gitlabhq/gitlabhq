import { isFunction, isString } from 'lodash';
import { Editor } from 'tiptap';
import {
  Bold,
  Italic,
  Code,
  Link,
  Image,
  Heading,
  Blockquote,
  HorizontalRule,
  BulletList,
  OrderedList,
  ListItem,
  HardBreak,
} from 'tiptap-extensions';
import { PROVIDE_SERIALIZER_OR_RENDERER_ERROR } from '../constants';
import CodeBlockHighlight from '../extensions/code_block_highlight';
import createMarkdownSerializer from './markdown_serializer';

const createEditor = async ({ content, renderMarkdown, serializer: customSerializer } = {}) => {
  if (!customSerializer && !isFunction(renderMarkdown)) {
    throw new Error(PROVIDE_SERIALIZER_OR_RENDERER_ERROR);
  }

  const editor = new Editor({
    extensions: [
      new Bold(),
      new Italic(),
      new Code(),
      new Link(),
      new Image(),
      new Heading({ levels: [1, 2, 3, 4, 5, 6] }),
      new Blockquote(),
      new HorizontalRule(),
      new BulletList(),
      new ListItem(),
      new OrderedList(),
      new CodeBlockHighlight(),
      new HardBreak(),
    ],
    editorProps: {
      attributes: {
        /*
         * Adds some padding to the contenteditable element where the user types.
         * Otherwise, the text cursor is not visible when its position is at the
         * beginning of a line.
         */
        class: 'gl-py-4 gl-px-5',
      },
    },
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
