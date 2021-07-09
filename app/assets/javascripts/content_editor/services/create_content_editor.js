import { Editor } from '@tiptap/vue-2';
import { isFunction } from 'lodash';
import { PROVIDE_SERIALIZER_OR_RENDERER_ERROR } from '../constants';
import * as Blockquote from '../extensions/blockquote';
import * as Bold from '../extensions/bold';
import * as BulletList from '../extensions/bullet_list';
import * as Code from '../extensions/code';
import * as CodeBlockHighlight from '../extensions/code_block_highlight';
import * as Document from '../extensions/document';
import * as Dropcursor from '../extensions/dropcursor';
import * as Gapcursor from '../extensions/gapcursor';
import * as HardBreak from '../extensions/hard_break';
import * as Heading from '../extensions/heading';
import * as History from '../extensions/history';
import * as HorizontalRule from '../extensions/horizontal_rule';
import * as Image from '../extensions/image';
import * as Italic from '../extensions/italic';
import * as Link from '../extensions/link';
import * as ListItem from '../extensions/list_item';
import * as OrderedList from '../extensions/ordered_list';
import * as Paragraph from '../extensions/paragraph';
import * as Strike from '../extensions/strike';
import * as Text from '../extensions/text';
import buildSerializerConfig from './build_serializer_config';
import { ContentEditor } from './content_editor';
import createMarkdownSerializer from './markdown_serializer';
import trackInputRulesAndShortcuts from './track_input_rules_and_shortcuts';

const collectTiptapExtensions = (extensions = []) =>
  extensions.map(({ tiptapExtension }) => tiptapExtension);

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
    Text,
  ];

  const allExtensions = [...builtInContentEditorExtensions, ...extensions];
  const tiptapExtensions = collectTiptapExtensions(allExtensions).map(trackInputRulesAndShortcuts);
  const tiptapEditor = createTiptapEditor({ extensions: tiptapExtensions, ...tiptapOptions });
  const serializerConfig = buildSerializerConfig(allExtensions);
  const serializer = createMarkdownSerializer({ render: renderMarkdown, serializerConfig });

  return new ContentEditor({ tiptapEditor, serializer });
};
