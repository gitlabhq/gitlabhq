// See https://docs.gitlab.com/ee/development/gitlab_flavored_markdown/specification_guide/#markdown-snapshot-testing
// for documentation on this spec.

import fs from 'fs';
import path from 'path';
import jsYaml from 'js-yaml';
import { pick } from 'lodash';
import {
  IMPLEMENTATION_ERROR_MSG,
  renderHtmlAndJsonForAllExamples,
} from './render_html_and_json_for_all_examples';

const filterExamples = (examples) => {
  const focusedMarkdownExamples = process.env.FOCUSED_MARKDOWN_EXAMPLES?.split(',') || [];
  if (!focusedMarkdownExamples.length) {
    return examples;
  }
  return pick(examples, focusedMarkdownExamples);
};

const loadExamples = (dir, fileName) => {
  const yaml = fs.readFileSync(path.join(dir, fileName));
  const examples = jsYaml.safeLoad(yaml, {});
  return filterExamples(examples);
};

// eslint-disable-next-line jest/no-export
export const describeMarkdownSnapshots = (description, glfmSpecificationDir) => {
  let actualHtmlAndJsonExamples;
  let skipRunningSnapshotWysiwygHtmlTests;
  let skipRunningSnapshotProsemirrorJsonTests;

  const exampleStatuses = loadExamples(
    path.join(glfmSpecificationDir, 'input', 'gitlab_flavored_markdown'),
    'glfm_example_status.yml',
  );
  const glfmExampleSnapshotsDir = path.join(glfmSpecificationDir, 'example_snapshots');
  const markdownExamples = loadExamples(glfmExampleSnapshotsDir, 'markdown.yml');
  const expectedHtmlExamples = loadExamples(glfmExampleSnapshotsDir, 'html.yml');
  const expectedProseMirrorJsonExamples = loadExamples(
    glfmExampleSnapshotsDir,
    'prosemirror_json.yml',
  );

  beforeAll(async () => {
    return renderHtmlAndJsonForAllExamples(markdownExamples).then((examples) => {
      actualHtmlAndJsonExamples = examples;
    });
  });

  describe(description, () => {
    const exampleNames = Object.keys(markdownExamples);

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
        it(`${exampleNamePrefix} HTML`, async () => {
          const expectedHtml = expectedHtmlExamples[name].wysiwyg;
          const { html: actualHtml } = actualHtmlAndJsonExamples[name];

          // noinspection JSUnresolvedFunction (required to avoid RubyMine type inspection warning, because custom matchers auto-imported via Jest test setup are not automatically resolved - see https://youtrack.jetbrains.com/issue/WEB-42350/matcher-for-jest-is-not-recognized-but-it-is-runable)
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
        it.todo(
          `${exampleNamePrefix} ProseMirror JSON: ${skipRunningSnapshotProsemirrorJsonTests}`,
        );
      } else {
        it(`${exampleNamePrefix} ProseMirror JSON`, async () => {
          const expectedJson = expectedProseMirrorJsonExamples[name];
          const { json: actualJson } = actualHtmlAndJsonExamples[name];

          // noinspection JSUnresolvedFunction
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
};
