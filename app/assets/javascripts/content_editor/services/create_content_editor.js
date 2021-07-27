import { Editor } from '@tiptap/vue-2';
import { isFunction } from 'lodash';
import { PROVIDE_SERIALIZER_OR_RENDERER_ERROR } from '../constants';
import Blockquote from '../extensions/blockquote';
import Bold from '../extensions/bold';
import BulletList from '../extensions/bullet_list';
import Code from '../extensions/code';
import CodeBlockHighlight from '../extensions/code_block_highlight';
import Document from '../extensions/document';
import Dropcursor from '../extensions/dropcursor';
import Gapcursor from '../extensions/gapcursor';
import HardBreak from '../extensions/hard_break';
import Heading from '../extensions/heading';
import History from '../extensions/history';
import HorizontalRule from '../extensions/horizontal_rule';
import Image from '../extensions/image';
import Italic from '../extensions/italic';
import Link from '../extensions/link';
import ListItem from '../extensions/list_item';
import OrderedList from '../extensions/ordered_list';
import Paragraph from '../extensions/paragraph';
import Strike from '../extensions/strike';
import Table from '../extensions/table';
import TableCell from '../extensions/table_cell';
import TableHeader from '../extensions/table_header';
import TableRow from '../extensions/table_row';
import Text from '../extensions/text';
import { ContentEditor } from './content_editor';
import createMarkdownSerializer from './markdown_serializer';
import trackInputRulesAndShortcuts from './track_input_rules_and_shortcuts';

const createTiptapEditor = ({ extensions = [], ...options } = {}) =>
  new Editor({
    extensions: [...extensions],
    editorProps: {
      attributes: {
        class: 'gl-outline-0!',
      },
    },
    ...options,
  });

export const createContentEditor = ({
  renderMarkdown,
  uploadsPath,
  extensions = [],
  serializerConfig = { marks: {}, nodes: {} },
  tiptapOptions,
} = {}) => {
  if (!isFunction(renderMarkdown)) {
    throw new Error(PROVIDE_SERIALIZER_OR_RENDERER_ERROR);
  }

  const builtInContentEditorExtensions = [
    Blockquote,
    Bold,
    BulletList,
    Code,
    CodeBlockHighlight,
    Document,
    Dropcursor,
    Gapcursor,
    HardBreak,
    Heading,
    History,
    HorizontalRule,
    Image.configure({ uploadsPath, renderMarkdown }),
    Italic,
    Link,
    ListItem,
    OrderedList,
    Paragraph,
    Strike,
    TableCell,
    TableHeader,
    TableRow,
    Table,
    Text,
  ];

  const allExtensions = [...builtInContentEditorExtensions, ...extensions];
  const trackedExtensions = allExtensions.map(trackInputRulesAndShortcuts);
  const tiptapEditor = createTiptapEditor({ extensions: trackedExtensions, ...tiptapOptions });
  const serializer = createMarkdownSerializer({ render: renderMarkdown, serializerConfig });

  return new ContentEditor({ tiptapEditor, serializer });
};
