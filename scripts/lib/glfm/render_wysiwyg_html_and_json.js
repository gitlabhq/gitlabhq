import fs from 'fs';
import jsYaml from 'js-yaml';
import { renderHtmlAndJsonForAllExamples } from 'jest/content_editor/render_html_and_json_for_all_examples';

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
// This script should be invoked via jest with the a command similar to the following:
// yarn jest --testMatch '**/render_wysiwyg_html_and_json.js' ./scripts/lib/glfm/render_wysiwyg_html_and_json.js
it('serializes html to prosemirror json', async () => {
  jest.setTimeout(20000);

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
