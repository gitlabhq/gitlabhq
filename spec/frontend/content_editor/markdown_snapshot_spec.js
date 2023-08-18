// See https://docs.gitlab.com/ee/development/gitlab_flavored_markdown/specification_guide/#markdown-snapshot-testing
// for documentation on this spec.
//
// NOTE: Unlike the backend markdown_snapshot_spec.rb which has a CE and EE version, there is only
// one version of this spec. This is because the frontend markdown rendering does not require EE-only
// backend features.

import jsYaml from 'js-yaml';
import { pick } from 'lodash';
import glfmExampleStatusYml from '../../../glfm_specification/input/gitlab_flavored_markdown/glfm_example_status.yml';
import markdownYml from '../../../glfm_specification/output_example_snapshots/markdown.yml';
import htmlYml from '../../../glfm_specification/output_example_snapshots/html.yml';
import prosemirrorJsonYml from '../../../glfm_specification/output_example_snapshots/prosemirror_json.yml';
import {
  IMPLEMENTATION_ERROR_MSG,
  renderHtmlAndJsonForAllExamples,
} from './render_html_and_json_for_all_examples';

jest.mock('~/emoji');

const filterExamples = (examples) => {
  const focusedMarkdownExamples = process.env.FOCUSED_MARKDOWN_EXAMPLES?.split(',') || [];
  if (!focusedMarkdownExamples.length) {
    return examples;
  }
  return pick(examples, focusedMarkdownExamples);
};

const loadExamples = (yaml) => {
  const examples = jsYaml.safeLoad(yaml, {});
  return filterExamples(examples);
};

describe('markdown example snapshots in ContentEditor', () => {
  let actualHtmlAndJsonExamples;
  let skipRunningSnapshotWysiwygHtmlTests;
  let skipRunningSnapshotProsemirrorJsonTests;

  const exampleStatuses = loadExamples(glfmExampleStatusYml);
  const markdownExamples = loadExamples(markdownYml);
  const expectedHtmlExamples = loadExamples(htmlYml);
  const expectedProseMirrorJsonExamples = loadExamples(prosemirrorJsonYml);
  const exampleNames = Object.keys(markdownExamples);

  beforeAll(() => {
    return renderHtmlAndJsonForAllExamples(markdownExamples).then((examples) => {
      actualHtmlAndJsonExamples = examples;
    });
  });

  describe.each(exampleNames)('%s', (name) => {
    const exampleNamePrefix = 'verifies conversion of GLFM to';
    skipRunningSnapshotWysiwygHtmlTests =
      exampleStatuses[name]?.skip_running_snapshot_wysiwyg_html_tests;
    skipRunningSnapshotProsemirrorJsonTests =
      exampleStatuses[name]?.skip_running_snapshot_prosemirror_json_tests;

    const markdown = markdownExamples[name];

    if (skipRunningSnapshotWysiwygHtmlTests) {
      it.todo(`${exampleNamePrefix} HTML: ${skipRunningSnapshotWysiwygHtmlTests}`);
    } else {
      it(`${exampleNamePrefix} HTML`, () => {
        const expectedHtml = expectedHtmlExamples[name].wysiwyg;
        const { html: actualHtml } = actualHtmlAndJsonExamples[name];

        expect(actualHtml).toMatchExpectedForMarkdown(
          'HTML',
          name,
          markdown,
          IMPLEMENTATION_ERROR_MSG,
          expectedHtml,
        );
      });
    }

    if (skipRunningSnapshotProsemirrorJsonTests) {
      it.todo(`${exampleNamePrefix} ProseMirror JSON: ${skipRunningSnapshotProsemirrorJsonTests}`);
    } else {
      it(`${exampleNamePrefix} ProseMirror JSON`, () => {
        const expectedJson = expectedProseMirrorJsonExamples[name];
        const { json: actualJson } = actualHtmlAndJsonExamples[name];

        expect(actualJson).toMatchExpectedForMarkdown(
          'JSON',
          name,
          markdown,
          IMPLEMENTATION_ERROR_MSG,
          expectedJson,
        );
      });
    }
  });
});
