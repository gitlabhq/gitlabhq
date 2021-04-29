import Blockquote from '@tiptap/extension-blockquote';
import Bold from '@tiptap/extension-bold';
import BulletList from '@tiptap/extension-bullet-list';
import Code from '@tiptap/extension-code';
import Document from '@tiptap/extension-document';
import Dropcursor from '@tiptap/extension-dropcursor';
import Gapcursor from '@tiptap/extension-gapcursor';
import HardBreak from '@tiptap/extension-hard-break';
import Heading from '@tiptap/extension-heading';
import History from '@tiptap/extension-history';
import HorizontalRule from '@tiptap/extension-horizontal-rule';
import Image from '@tiptap/extension-image';
import Italic from '@tiptap/extension-italic';
import Link from '@tiptap/extension-link';
import ListItem from '@tiptap/extension-list-item';
import OrderedList from '@tiptap/extension-ordered-list';
import Paragraph from '@tiptap/extension-paragraph';
import Text from '@tiptap/extension-text';
import { Editor } from '@tiptap/vue-2';
import { isFunction } from 'lodash';

import { PROVIDE_SERIALIZER_OR_RENDERER_ERROR } from '../constants';
import CodeBlockHighlight from '../extensions/code_block_highlight';
import { ContentEditor } from './content_editor';
import createMarkdownSerializer from './markdown_serializer';

const createTiptapEditor = ({ extensions = [], options } = {}) =>
  new Editor({
    extensions: [
      Dropcursor,
      Gapcursor,
      History,
      Document,
      Text,
      Paragraph,
      Bold,
      Italic,
      Code,
      Link,
      Heading,
      HardBreak,
      Blockquote,
      HorizontalRule,
      BulletList,
      OrderedList,
      ListItem,
      Image.configure({ inline: true }),
      CodeBlockHighlight,
      ...extensions,
    ],
    editorProps: {
      attributes: {
        class: 'gl-outline-0!',
      },
    },
    ...options,
  });

export const createContentEditor = ({ renderMarkdown, extensions = [], tiptapOptions } = {}) => {
  if (!isFunction(renderMarkdown)) {
    throw new Error(PROVIDE_SERIALIZER_OR_RENDERER_ERROR);
  }

  const tiptapEditor = createTiptapEditor({ extensions, options: tiptapOptions });
  const serializer = createMarkdownSerializer({ render: renderMarkdown });

  return new ContentEditor({ tiptapEditor, serializer });
};
