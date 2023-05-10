import {
  MarkdownSerializer as ProseMirrorMarkdownSerializer,
  defaultMarkdownSerializer,
} from '~/lib/prosemirror_markdown_serializer';
import Audio from '../extensions/audio';
import Blockquote from '../extensions/blockquote';
import Bold from '../extensions/bold';
import BulletList from '../extensions/bullet_list';
import Code from '../extensions/code';
import CodeBlockHighlight from '../extensions/code_block_highlight';
import DescriptionItem from '../extensions/description_item';
import DescriptionList from '../extensions/description_list';
import Details from '../extensions/details';
import DetailsContent from '../extensions/details_content';
import DrawioDiagram from '../extensions/drawio_diagram';
import Comment from '../extensions/comment';
import Diagram from '../extensions/diagram';
import Emoji from '../extensions/emoji';
import Figure from '../extensions/figure';
import FigureCaption from '../extensions/figure_caption';
import FootnoteDefinition from '../extensions/footnote_definition';
import FootnoteReference from '../extensions/footnote_reference';
import Frontmatter from '../extensions/frontmatter';
import HardBreak from '../extensions/hard_break';
import Heading from '../extensions/heading';
import HorizontalRule from '../extensions/horizontal_rule';
import Highlight from '../extensions/highlight';
import HTMLMarks from '../extensions/html_marks';
import HTMLNodes from '../extensions/html_nodes';
import Image from '../extensions/image';
import InlineDiff from '../extensions/inline_diff';
import Italic from '../extensions/italic';
import Link from '../extensions/link';
import ListItem from '../extensions/list_item';
import MathInline from '../extensions/math_inline';
import OrderedList from '../extensions/ordered_list';
import Paragraph from '../extensions/paragraph';
import Reference from '../extensions/reference';
import ReferenceLabel from '../extensions/reference_label';
import ReferenceDefinition from '../extensions/reference_definition';
import Strike from '../extensions/strike';
import Subscript from '../extensions/subscript';
import Superscript from '../extensions/superscript';
import Table from '../extensions/table';
import TableCell from '../extensions/table_cell';
import TableHeader from '../extensions/table_header';
import TableOfContents from '../extensions/table_of_contents';
import TableRow from '../extensions/table_row';
import TaskItem from '../extensions/task_item';
import TaskList from '../extensions/task_list';
import Text from '../extensions/text';
import Video from '../extensions/video';
import WordBreak from '../extensions/word_break';
import {
  renderComment,
  renderCodeBlock,
  renderHardBreak,
  renderTable,
  renderTableCell,
  renderTableRow,
  openTag,
  closeTag,
  renderOrderedList,
  renderImage,
  renderPlayable,
  renderHTMLNode,
  renderContent,
  renderBulletList,
  renderReference,
  preserveUnchanged,
  bold,
  italic,
  link,
  code,
  strike,
} from './serialization_helpers';

const defaultSerializerConfig = {
  marks: {
    [Bold.name]: bold,
    [Italic.name]: italic,
    [Code.name]: code,
    [Subscript.name]: { open: '<sub>', close: '</sub>', mixable: true },
    [Superscript.name]: { open: '<sup>', close: '</sup>', mixable: true },
    [Highlight.name]: { open: '<mark>', close: '</mark>', mixable: true },
    [InlineDiff.name]: {
      mixable: true,
      open(_, mark) {
        return mark.attrs.type === 'addition' ? '{+' : '{-';
      },
      close(_, mark) {
        return mark.attrs.type === 'addition' ? '+}' : '-}';
      },
    },
    [Link.name]: link,
    [MathInline.name]: {
      open: (...args) => `$${defaultMarkdownSerializer.marks.code.open(...args)}`,
      close: (...args) => `${defaultMarkdownSerializer.marks.code.close(...args)}$`,
      escape: false,
    },
    [Strike.name]: strike,
    ...HTMLMarks.reduce(
      (acc, { name }) => ({
        ...acc,
        [name]: {
          mixable: true,
          open(state, node) {
            return openTag(name, node.attrs);
          },
          close: closeTag(name),
        },
      }),
      {},
    ),
  },

  nodes: {
    [Audio.name]: preserveUnchanged({
      render: renderPlayable,
      inline: true,
    }),
    [Blockquote.name]: preserveUnchanged((state, node) => {
      if (node.attrs.multiline) {
        state.write('>>>');
        state.ensureNewLine();
        state.renderContent(node);
        state.ensureNewLine();
        state.write('>>>');
        state.closeBlock(node);
      } else {
        state.wrapBlock('> ', null, node, () => state.renderContent(node));
      }
    }),
    [BulletList.name]: preserveUnchanged(renderBulletList),
    [CodeBlockHighlight.name]: preserveUnchanged(renderCodeBlock),
    [Comment.name]: renderComment,
    [Diagram.name]: preserveUnchanged(renderCodeBlock),
    [DrawioDiagram.name]: preserveUnchanged({
      render: renderImage,
      inline: true,
    }),
    [DescriptionList.name]: renderHTMLNode('dl', true),
    [DescriptionItem.name]: (state, node, parent, index) => {
      if (index === 1) state.ensureNewLine();
      renderHTMLNode(node.attrs.isTerm ? 'dt' : 'dd')(state, node);
      if (index === parent.childCount - 1) state.ensureNewLine();
    },
    [Details.name]: renderHTMLNode('details', true),
    [DetailsContent.name]: (state, node, parent, index) => {
      if (!index) renderHTMLNode('summary')(state, node);
      else {
        if (index === 1) state.ensureNewLine();
        renderContent(state, node);
        if (index === parent.childCount - 1) state.ensureNewLine();
      }
    },
    [Emoji.name]: (state, node) => {
      const { name } = node.attrs;

      state.write(`:${name}:`);
    },
    [FootnoteDefinition.name]: preserveUnchanged((state, node) => {
      state.write(`[^${node.attrs.identifier}]: `);
      state.renderInline(node);
      state.ensureNewLine();
    }),
    [FootnoteReference.name]: preserveUnchanged({
      render: (state, node) => {
        state.write(`[^${node.attrs.identifier}]`);
      },
      inline: true,
    }),
    [Frontmatter.name]: preserveUnchanged((state, node) => {
      const { language } = node.attrs;
      const syntax = {
        toml: '+++',
        json: ';;;',
        yaml: '---',
      }[language];

      state.write(`${syntax}\n`);
      state.text(node.textContent, false);
      state.ensureNewLine();
      state.write(syntax);
      state.closeBlock(node);
    }),
    [Figure.name]: renderHTMLNode('figure'),
    [FigureCaption.name]: renderHTMLNode('figcaption'),
    [HardBreak.name]: preserveUnchanged(renderHardBreak),
    [Heading.name]: preserveUnchanged(defaultMarkdownSerializer.nodes.heading),
    [HorizontalRule.name]: preserveUnchanged(defaultMarkdownSerializer.nodes.horizontal_rule),
    [Image.name]: preserveUnchanged({
      render: renderImage,
      inline: true,
    }),
    [ListItem.name]: preserveUnchanged(defaultMarkdownSerializer.nodes.list_item),
    [OrderedList.name]: preserveUnchanged(renderOrderedList),
    [Paragraph.name]: preserveUnchanged(defaultMarkdownSerializer.nodes.paragraph),
    [Reference.name]: renderReference,
    [ReferenceLabel.name]: renderReference,
    [ReferenceDefinition.name]: preserveUnchanged({
      render: (state, node, parent, index, same, sourceMarkdown) => {
        const nextSibling = parent.maybeChild(index + 1);

        state.text(same ? sourceMarkdown : node.textContent, false);

        /**
         * Do not insert a blank line between reference definitions
         * because it isn’t necessary and a more compact text format
         * is preferred.
         */
        if (!nextSibling || nextSibling.type.name !== ReferenceDefinition.name) {
          state.closeBlock(node);
        } else {
          state.ensureNewLine();
        }
      },
      overwriteSourcePreservationStrategy: true,
    }),
    [TableOfContents.name]: preserveUnchanged((state, node) => {
      state.write('[[_TOC_]]');
      state.closeBlock(node);
    }),
    [Table.name]: preserveUnchanged(renderTable),
    [TableCell.name]: renderTableCell,
    [TableHeader.name]: renderTableCell,
    [TableRow.name]: renderTableRow,
    [TaskItem.name]: preserveUnchanged((state, node) => {
      state.write(`[${node.attrs.checked ? 'x' : ' '}] `);
      if (!node.textContent) state.write('&nbsp;');
      state.renderContent(node);
    }),
    [TaskList.name]: preserveUnchanged((state, node) => {
      if (node.attrs.numeric) renderOrderedList(state, node);
      else renderBulletList(state, node);
    }),
    [Text.name]: defaultMarkdownSerializer.nodes.text,
    [Video.name]: preserveUnchanged({
      render: renderPlayable,
      inline: true,
    }),
    [WordBreak.name]: (state) => state.write('<wbr>'),
    ...HTMLNodes.reduce((serializers, htmlNode) => {
      return {
        ...serializers,
        [htmlNode.name]: (state, node) => renderHTMLNode(htmlNode.options.tagName)(state, node),
      };
    }, {}),
  },
};

const createChangeTracker = (doc, pristineDoc) => {
  const changeTracker = new WeakMap();
  const pristineSourceMarkdownMap = new Map();

  if (doc && pristineDoc) {
    pristineDoc.descendants((node) => {
      if (node.attrs.sourceMapKey) {
        pristineSourceMarkdownMap.set(`${node.attrs.sourceMapKey}${node.type.name}`, node);
      }
    });
    doc.descendants((node) => {
      const pristineNode = pristineSourceMarkdownMap.get(
        `${node.attrs.sourceMapKey}${node.type.name}`,
      );

      if (pristineNode) {
        changeTracker.set(node, node.eq(pristineNode));
      }
    });
  }

  return changeTracker;
};

/**
 * Converts a ProseMirror document to Markdown. See the
 * following documentation to learn how to implement
 * custom node and mark serializer functions.
 *
 * https://github.com/prosemirror/prosemirror-markdown
 *
 * @param {Object} params.nodes ProseMirror node serializer functions
 * @param {Object} params.marks ProseMirror marks serializer config
 *
 * @returns a markdown serializer
 */
export default ({ serializerConfig = {} } = {}) => ({
  /**
   * Serializes a ProseMirror document as Markdown. If a node contains
   * sourcemap metadata, the serializer is capable of restoring the
   * Markdown from which the node was generated using a Markdown
   * deserializer.
   *
   * See the Sourcemap metadata extension and the remark_markdown_deserializer
   * service for more information.
   *
   * @param {ProseMirror.Node} params.doc ProseMirror document to convert into Markdown
   * @param {ProseMirror.Node} params.pristineDoc Pristine version of the document that
   * should be converted into Markdown. This is used to detect which nodes in the document
   * changed.
   * @returns A String that represents the serialized document as Markdown
   */
  serialize: ({ doc, pristineDoc }) => {
    const changeTracker = createChangeTracker(doc, pristineDoc);
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

    return serializer.serialize(doc, {
      tightLists: true,
      changeTracker,
    });
  },
});
