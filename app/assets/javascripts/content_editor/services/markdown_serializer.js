import { MarkdownSerializer as ProseMirrorMarkdownSerializer } from '~/lib/prosemirror_markdown_serializer';
import * as extensions from '../extensions';
import codeSuggestion from './serializer/code_suggestion';
import code from './serializer/code';
import bold from './serializer/bold';
import italic from './serializer/italic';
import link from './serializer/link';
import strike from './serializer/strike';
import subscript from './serializer/subscript';
import superscript from './serializer/superscript';
import highlight from './serializer/highlight';
import inlineDiff from './serializer/inline_diff';
import mathInline from './serializer/math_inline';
import htmlMark from './serializer/html_mark';
import image from './serializer/image';
import audio from './serializer/audio';
import drawioDiagram from './serializer/drawio_diagram';
import video from './serializer/video';
import blockquote from './serializer/blockquote';
import codeBlock from './serializer/code_block';
import diagram from './serializer/diagram';
import descriptionList from './serializer/description_list';
import descriptionItem from './serializer/description_item';
import details from './serializer/details';
import detailsContent from './serializer/details_content';
import emoji from './serializer/emoji';
import footnoteDefinition from './serializer/footnote_definition';
import footnoteReference from './serializer/footnote_reference';
import frontmatter from './serializer/frontmatter';
import figure from './serializer/figure';
import figureCaption from './serializer/figure_caption';
import heading from './serializer/heading';
import horizontalRule from './serializer/horizontal_rule';
import listItem from './serializer/list_item';
import loading from './serializer/loading';
import htmlComment from './serializer/html_comment';
import referenceDefinition from './serializer/reference_definition';
import tableOfContents from './serializer/table_of_contents';
import taskItem from './serializer/task_item';
import taskList from './serializer/task_list';
import bulletList from './serializer/bullet_list';
import orderedList from './serializer/ordered_list';
import paragraph from './serializer/paragraph';
import hardBreak from './serializer/hard_break';
import text from './serializer/text';
import wordBreak from './serializer/word_break';
import referenceLabel from './serializer/reference_label';
import reference from './serializer/reference';
import tableCell from './serializer/table_cell';
import tableHeader from './serializer/table_header';
import tableRow from './serializer/table_row';
import table from './serializer/table';
import htmlNode from './serializer/html_node';

const defaultSerializerConfig = {
  marks: {
    [extensions.Bold.name]: bold,
    [extensions.Italic.name]: italic,
    [extensions.Code.name]: code,
    [extensions.Subscript.name]: subscript,
    [extensions.Superscript.name]: superscript,
    [extensions.Highlight.name]: highlight,
    [extensions.InlineDiff.name]: inlineDiff,
    [extensions.Link.name]: link,
    [extensions.MathInline.name]: mathInline,
    [extensions.Strike.name]: strike,
    ...extensions.HTMLMarks.reduce((acc, { name }) => ({ ...acc, [name]: htmlMark(name) }), {}),
  },

  nodes: {
    [extensions.Audio.name]: audio,
    [extensions.Blockquote.name]: blockquote,
    [extensions.BulletList.name]: bulletList,
    [extensions.CodeBlockHighlight.name]: codeBlock,
    [extensions.Diagram.name]: diagram,
    [extensions.CodeSuggestion.name]: codeSuggestion,
    [extensions.DrawioDiagram.name]: drawioDiagram,
    [extensions.DescriptionList.name]: descriptionList,
    [extensions.DescriptionItem.name]: descriptionItem,
    [extensions.Details.name]: details,
    [extensions.DetailsContent.name]: detailsContent,
    [extensions.Emoji.name]: emoji,
    [extensions.FootnoteDefinition.name]: footnoteDefinition,
    [extensions.FootnoteReference.name]: footnoteReference,
    [extensions.Frontmatter.name]: frontmatter,
    [extensions.Figure.name]: figure,
    [extensions.FigureCaption.name]: figureCaption,
    [extensions.HardBreak.name]: hardBreak,
    [extensions.Heading.name]: heading,
    [extensions.HorizontalRule.name]: horizontalRule,
    [extensions.Image.name]: image,
    [extensions.ListItem.name]: listItem,
    [extensions.Loading.name]: loading,
    [extensions.OrderedList.name]: orderedList,
    [extensions.Paragraph.name]: paragraph,
    [extensions.HTMLComment.name]: htmlComment,
    [extensions.Reference.name]: reference,
    [extensions.ReferenceLabel.name]: referenceLabel,
    [extensions.ReferenceDefinition.name]: referenceDefinition,
    [extensions.TableOfContents.name]: tableOfContents,
    [extensions.Table.name]: table,
    [extensions.TableCell.name]: tableCell,
    [extensions.TableHeader.name]: tableHeader,
    [extensions.TableRow.name]: tableRow,
    [extensions.TaskItem.name]: taskItem,
    [extensions.TaskList.name]: taskList,
    [extensions.Text.name]: text,
    [extensions.Video.name]: video,
    [extensions.WordBreak.name]: wordBreak,
    ...extensions.HTMLNodes.reduce((acc, { name }) => ({ ...acc, [name]: htmlNode(name) }), {}),
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

      node.marks?.forEach((mark) => {
        if (mark.attrs.sourceMapKey) {
          pristineSourceMarkdownMap.set(`${mark.attrs.sourceMapKey}${mark.type.name}`, {
            mark,
            node,
          });
        }
      });
    });

    doc.descendants((node) => {
      const pristineNode = pristineSourceMarkdownMap.get(
        `${node.attrs.sourceMapKey}${node.type.name}`,
      );

      if (pristineNode) {
        changeTracker.set(node, node.eq(pristineNode));
      }

      node.marks?.forEach((mark) => {
        const { node: pristineNodeForMark, mark: pristineMark } =
          pristineSourceMarkdownMap.get(`${mark.attrs.sourceMapKey}${mark.type.name}`) || {};

        if (pristineMark) {
          changeTracker.set(mark, mark.eq(pristineMark) && node.eq(pristineNodeForMark));
        }
      });
    });
  }

  return changeTracker;
};

export default class MarkdownSerializer {
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
  constructor({ serializerConfig = {} } = {}) {
    this.serializerConfig = serializerConfig;
  }
  /**
   * Serializes a ProseMirror document as Markdown. If a node contains
   * sourcemap metadata, the serializer is capable of restoring the
   * Markdown from which the node was generated using a Markdown
   * deserializer.
   *
   * See the Sourcemap metadata extension for more information.
   *
   * @param {ProseMirror.Node} params.doc ProseMirror document to convert into Markdown
   * @param {ProseMirror.Node} params.pristineDoc Pristine version of the document that
   * should be converted into Markdown. This is used to detect which nodes in the document
   * changed.
   * @returns A String that represents the serialized document as Markdown
   */
  serialize({ doc, pristineDoc }, { useCanonicalSrc = true, skipEmptyNodes = false } = {}) {
    const changeTracker = createChangeTracker(doc, pristineDoc);
    const serializer = new ProseMirrorMarkdownSerializer(
      {
        ...defaultSerializerConfig.nodes,
        ...this.serializerConfig.nodes,
      },
      {
        ...defaultSerializerConfig.marks,
        ...this.serializerConfig.marks,
      },
    );

    const serialized = serializer.serialize(doc, {
      tightLists: true,
      useCanonicalSrc,
      skipEmptyNodes,
      changeTracker,
      escapeExtraCharacters: /<|>/g,
    });

    // If the pristine document contains link reference definitions,
    // append them to the serialized document
    if (pristineDoc?.attrs.referenceDefinitions) {
      return `${serialized}\n\n${pristineDoc.attrs.referenceDefinitions}`;
    }

    return serialized;
  }
}
