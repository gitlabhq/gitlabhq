import fs from 'fs';
import { DOMSerializer } from 'prosemirror-model';
import jsYaml from 'js-yaml';
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
import Division from '~/content_editor/extensions/division';
import Emoji from '~/content_editor/extensions/emoji';
import Figure from '~/content_editor/extensions/figure';
import FigureCaption from '~/content_editor/extensions/figure_caption';
import FootnoteDefinition from '~/content_editor/extensions/footnote_definition';
import FootnoteReference from '~/content_editor/extensions/footnote_reference';
import FootnotesSection from '~/content_editor/extensions/footnotes_section';
import HardBreak from '~/content_editor/extensions/hard_break';
import Heading from '~/content_editor/extensions/heading';
import HorizontalRule from '~/content_editor/extensions/horizontal_rule';
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
import { setTestTimeout } from 'jest/__helpers__/timeout';

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
    Division,
    Emoji,
    FootnoteDefinition,
    FootnoteReference,
    FootnotesSection,
    Figure,
    FigureCaption,
    HardBreak,
    Heading,
    HorizontalRule,
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

async function renderMarkdownToHTMLAndJSON(markdown, schema, deserializer) {
  let prosemirrorDocument;
  try {
    const { document } = await deserializer.deserialize({ schema, content: markdown });
    prosemirrorDocument = document;
  } catch (e) {
    const errorMsg = `Error - check implementation:\n${e.message}`;
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

function renderHtmlAndJsonForAllExamples(markdownExamples) {
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

/* eslint-disable no-undef */
jest.mock('~/emoji');

// The purpose of this file is to deserialize markdown examples
// to WYSIWYG HTML and to prosemirror documents in JSON form, using
// the logic implemented as part of the Content Editor.
//
// It reads an input YAML file containing all the markdown examples,
// and outputs a YAML files containing the rendered HTML and JSON
// corresponding each markdown example.
//
// The input and output file paths are provides as command line arguments.
//
// Although it is implemented as a Jest test, it is not a unit test. We use
// Jest because that is the simplest environment in which to execute the
// relevant Content Editor logic.
//
//
// This script should be invoked via jest with the a command similar to the following:
// yarn jest --testMatch '**/render_wysiwyg_html_and_json.js' ./scripts/lib/glfm/render_wysiwyg_html_and_json.js
it('serializes html to prosemirror json', async () => {
  setTestTimeout(20000);

  const inputMarkdownTempfilePath = process.env.INPUT_MARKDOWN_YML_PATH;
  expect(inputMarkdownTempfilePath).not.toBeUndefined();
  const outputWysiwygHtmlAndJsonTempfilePath =
    process.env.OUTPUT_WYSIWYG_HTML_AND_JSON_TEMPFILE_PATH;
  expect(outputWysiwygHtmlAndJsonTempfilePath).not.toBeUndefined();
  /* eslint-enable no-undef */

  const markdownExamples = jsYaml.safeLoad(fs.readFileSync(inputMarkdownTempfilePath), {});

  const htmlAndJsonExamples = await renderHtmlAndJsonForAllExamples(markdownExamples);

  const htmlAndJsonExamplesYamlString = jsYaml.safeDump(htmlAndJsonExamples, {});
  fs.writeFileSync(outputWysiwygHtmlAndJsonTempfilePath, htmlAndJsonExamplesYamlString);
});
