import {
  MarkdownSerializer as ProseMirrorMarkdownSerializer,
  defaultMarkdownSerializer,
} from 'prosemirror-markdown/src/to_markdown';
import { DOMParser as ProseMirrorDOMParser } from 'prosemirror-model';
import Blockquote from '../extensions/blockquote';
import Bold from '../extensions/bold';
import BulletList from '../extensions/bullet_list';
import Code from '../extensions/code';
import CodeBlockHighlight from '../extensions/code_block_highlight';
import Emoji from '../extensions/emoji';
import HardBreak from '../extensions/hard_break';
import Heading from '../extensions/heading';
import HorizontalRule from '../extensions/horizontal_rule';
import Image from '../extensions/image';
import InlineDiff from '../extensions/inline_diff';
import Italic from '../extensions/italic';
import Link from '../extensions/link';
import ListItem from '../extensions/list_item';
import OrderedList from '../extensions/ordered_list';
import Paragraph from '../extensions/paragraph';
import Reference from '../extensions/reference';
import Strike from '../extensions/strike';
import Subscript from '../extensions/subscript';
import Superscript from '../extensions/superscript';
import Table from '../extensions/table';
import TableCell from '../extensions/table_cell';
import TableHeader from '../extensions/table_header';
import TableRow from '../extensions/table_row';
import TaskItem from '../extensions/task_item';
import TaskList from '../extensions/task_list';
import Text from '../extensions/text';

const defaultSerializerConfig = {
  marks: {
    [Bold.name]: defaultMarkdownSerializer.marks.strong,
    [Code.name]: defaultMarkdownSerializer.marks.code,
    [Italic.name]: { open: '_', close: '_', mixable: true, expelEnclosingWhitespace: true },
    [Subscript.name]: { open: '<sub>', close: '</sub>', mixable: true },
    [Superscript.name]: { open: '<sup>', close: '</sup>', mixable: true },
    [InlineDiff.name]: {
      mixable: true,
      open(state, mark) {
        return mark.attrs.type === 'addition' ? '{+' : '{-';
      },
      close(state, mark) {
        return mark.attrs.type === 'addition' ? '+}' : '-}';
      },
    },
    [Link.name]: {
      open() {
        return '[';
      },
      close(state, mark) {
        const href = mark.attrs.canonicalSrc || mark.attrs.href;
        return `](${state.esc(href)}${
          mark.attrs.title ? ` ${state.quote(mark.attrs.title)}` : ''
        })`;
      },
    },
    [Strike.name]: {
      open: '~~',
      close: '~~',
      mixable: true,
      expelEnclosingWhitespace: true,
    },
  },
  nodes: {
    [Blockquote.name]: defaultMarkdownSerializer.nodes.blockquote,
    [BulletList.name]: defaultMarkdownSerializer.nodes.bullet_list,
    [CodeBlockHighlight.name]: (state, node) => {
      state.write(`\`\`\`${node.attrs.language || ''}\n`);
      state.text(node.textContent, false);
      state.ensureNewLine();
      state.write('```');
      state.closeBlock(node);
    },
    [Emoji.name]: (state, node) => {
      const { name } = node.attrs;

      state.write(`:${name}:`);
    },
    [HardBreak.name]: defaultMarkdownSerializer.nodes.hard_break,
    [Heading.name]: defaultMarkdownSerializer.nodes.heading,
    [HorizontalRule.name]: defaultMarkdownSerializer.nodes.horizontal_rule,
    [Image.name]: (state, node) => {
      const { alt, canonicalSrc, src, title } = node.attrs;
      const quotedTitle = title ? ` ${state.quote(title)}` : '';

      state.write(`![${state.esc(alt || '')}](${state.esc(canonicalSrc || src)}${quotedTitle})`);
    },
    [ListItem.name]: defaultMarkdownSerializer.nodes.list_item,
    [OrderedList.name]: defaultMarkdownSerializer.nodes.ordered_list,
    [Paragraph.name]: defaultMarkdownSerializer.nodes.paragraph,
    [Reference.name]: (state, node) => {
      state.write(node.attrs.originalText || node.attrs.text);
    },
    [Table.name]: (state, node) => {
      state.renderContent(node);
    },
    [TableCell.name]: (state, node) => {
      state.renderInline(node);
    },
    [TableHeader.name]: (state, node) => {
      state.renderInline(node);
    },
    [TableRow.name]: (state, node) => {
      const isHeaderRow = node.child(0).type.name === 'tableHeader';

      const renderRow = () => {
        const cellWidths = [];

        state.flushClose(1);

        state.write('| ');
        node.forEach((cell, _, i) => {
          if (i) state.write(' | ');

          const { length } = state.out;
          state.render(cell, node, i);
          cellWidths.push(state.out.length - length);
        });
        state.write(' |');

        state.closeBlock(node);

        return cellWidths;
      };

      const renderHeaderRow = (cellWidths) => {
        state.flushClose(1);

        state.write('|');
        node.forEach((cell, _, i) => {
          if (i) state.write('|');

          state.write(cell.attrs.align === 'center' ? ':' : '-');
          state.write(state.repeat('-', cellWidths[i]));
          state.write(cell.attrs.align === 'center' || cell.attrs.align === 'right' ? ':' : '-');
        });
        state.write('|');

        state.closeBlock(node);
      };

      if (isHeaderRow) {
        renderHeaderRow(renderRow());
      } else {
        renderRow();
      }
    },
    [TaskItem.name]: (state, node) => {
      state.write(`[${node.attrs.checked ? 'x' : ' '}] `);
      state.renderContent(node);
    },
    [TaskList.name]: (state, node) => {
      if (node.attrs.type === 'ul') defaultMarkdownSerializer.nodes.bullet_list(state, node);
      else defaultMarkdownSerializer.nodes.ordered_list(state, node);
    },
    [Text.name]: defaultMarkdownSerializer.nodes.text,
  },
};

const wrapHtmlPayload = (payload) => `<div>${payload}</div>`;

/**
 * A markdown serializer converts arbitrary Markdown content
 * into a ProseMirror document and viceversa. To convert Markdown
 * into a ProseMirror document, the Markdown should be rendered.
 *
 * The client should provide a render function to allow flexibility
 * on the desired rendering approach.
 *
 * @param {Function} params.render Render function
 * that parses the Markdown and converts it into HTML.
 * @returns a markdown serializer
 */
export default ({ render = () => null, serializerConfig }) => ({
  /**
   * Converts a Markdown string into a ProseMirror JSONDocument based
   * on a ProseMirror schema.
   * @param {ProseMirror.Schema} params.schema A ProseMirror schema that defines
   * the types of content supported in the document
   * @param {String} params.content An arbitrary markdown string
   * @returns A ProseMirror JSONDocument
   */
  deserialize: async ({ schema, content }) => {
    const html = await render(content);

    if (!html) {
      return null;
    }

    const parser = new DOMParser();
    const {
      body: { firstElementChild },
    } = parser.parseFromString(wrapHtmlPayload(html), 'text/html');
    const state = ProseMirrorDOMParser.fromSchema(schema).parse(firstElementChild);

    return state.toJSON();
  },

  /**
   * Converts a ProseMirror JSONDocument based
   * on a ProseMirror schema into Markdown
   * @param {ProseMirror.Schema} params.schema A ProseMirror schema that defines
   * the types of content supported in the document
   * @param {String} params.content A ProseMirror JSONDocument
   * @returns A Markdown string
   */
  serialize: ({ schema, content }) => {
    const proseMirrorDocument = schema.nodeFromJSON(content);
    const serializer = new ProseMirrorMarkdownSerializer(
      {
        ...defaultSerializerConfig.nodes,
        ...serializerConfig.nodes,
      },
      {
        ...defaultSerializerConfig.marks,
        ...serializerConfig.marks,
      },
    );

    return serializer.serialize(proseMirrorDocument, {
      tightLists: true,
    });
  },
});
