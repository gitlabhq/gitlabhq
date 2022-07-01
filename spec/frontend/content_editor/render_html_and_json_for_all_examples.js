import { DOMSerializer } from 'prosemirror-model';
// TODO: DRY up duplication with spec/frontend/content_editor/services/markdown_serializer_spec.js
//  See https://gitlab.com/groups/gitlab-org/-/epics/7719#plan
import Blockquote from '~/content_editor/extensions/blockquote';
import Bold from '~/content_editor/extensions/bold';
import BulletList from '~/content_editor/extensions/bullet_list';
import Code from '~/content_editor/extensions/code';
import CodeBlockHighlight from '~/content_editor/extensions/code_block_highlight';
import DescriptionItem from '~/content_editor/extensions/description_item';
import DescriptionList from '~/content_editor/extensions/description_list';
import Details from '~/content_editor/extensions/details';
import DetailsContent from '~/content_editor/extensions/details_content';
import Emoji from '~/content_editor/extensions/emoji';
import Figure from '~/content_editor/extensions/figure';
import FigureCaption from '~/content_editor/extensions/figure_caption';
import FootnoteDefinition from '~/content_editor/extensions/footnote_definition';
import FootnoteReference from '~/content_editor/extensions/footnote_reference';
import FootnotesSection from '~/content_editor/extensions/footnotes_section';
import HardBreak from '~/content_editor/extensions/hard_break';
import Heading from '~/content_editor/extensions/heading';
import HorizontalRule from '~/content_editor/extensions/horizontal_rule';
import HTMLNodes from '~/content_editor/extensions/html_nodes';
import Image from '~/content_editor/extensions/image';
import InlineDiff from '~/content_editor/extensions/inline_diff';
import Italic from '~/content_editor/extensions/italic';
import Link from '~/content_editor/extensions/link';
import ListItem from '~/content_editor/extensions/list_item';
import OrderedList from '~/content_editor/extensions/ordered_list';
import Strike from '~/content_editor/extensions/strike';
import Table from '~/content_editor/extensions/table';
import TableCell from '~/content_editor/extensions/table_cell';
import TableHeader from '~/content_editor/extensions/table_header';
import TableRow from '~/content_editor/extensions/table_row';
import TaskItem from '~/content_editor/extensions/task_item';
import TaskList from '~/content_editor/extensions/task_list';
import createMarkdownDeserializer from '~/content_editor/services/remark_markdown_deserializer';
import { createTestEditor } from 'jest/content_editor/test_utils';

const tiptapEditor = createTestEditor({
  extensions: [
    Blockquote,
    Bold,
    BulletList,
    Code,
    CodeBlockHighlight,
    DescriptionItem,
    DescriptionList,
    Details,
    DetailsContent,
    Emoji,
    FootnoteDefinition,
    FootnoteReference,
    FootnotesSection,
    Figure,
    FigureCaption,
    HardBreak,
    Heading,
    HorizontalRule,
    ...HTMLNodes,
    Image,
    InlineDiff,
    Italic,
    Link,
    ListItem,
    OrderedList,
    Strike,
    Table,
    TableCell,
    TableHeader,
    TableRow,
    TaskItem,
    TaskList,
  ],
});

export const IMPLEMENTATION_ERROR_MSG = 'Error - check implementation';

async function renderMarkdownToHTMLAndJSON(markdown, schema, deserializer) {
  let prosemirrorDocument;
  try {
    const { document } = await deserializer.deserialize({ schema, content: markdown });
    prosemirrorDocument = document;
  } catch (e) {
    const errorMsg = `${IMPLEMENTATION_ERROR_MSG}:\n${e.message}`;
    return {
      html: errorMsg,
      json: errorMsg,
    };
  }

  const documentFragment = DOMSerializer.fromSchema(schema).serializeFragment(
    prosemirrorDocument.content,
  );
  const htmlString = documentFragment.firstChild.outerHTML;

  const json = prosemirrorDocument.toJSON();
  const jsonString = JSON.stringify(json, null, 2);
  return { html: htmlString, json: jsonString };
}

export function renderHtmlAndJsonForAllExamples(markdownExamples) {
  const { schema } = tiptapEditor;
  const deserializer = createMarkdownDeserializer();
  const exampleNames = Object.keys(markdownExamples);

  return exampleNames.reduce(async (promisedExamples, exampleName) => {
    const markdown = markdownExamples[exampleName];
    const htmlAndJson = await renderMarkdownToHTMLAndJSON(markdown, schema, deserializer);
    const examples = await promisedExamples;
    examples[exampleName] = htmlAndJson;
    return examples;
  }, Promise.resolve({}));
}
