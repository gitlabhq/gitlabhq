import createEditor from '~/content_editor/services/create_editor';
import toMarkdown from '~/content_editor/services/to_markdown';
import { loadMarkdownApiExamples, loadMarkdownApiResult } from './markdown_processing_examples';

describe('markdown processing', () => {
  // Ensure we generate same markdown that was provided to Markdown API.
  it.each(loadMarkdownApiExamples())('correctly handles %s', async (testName, markdown) => {
    const { html } = loadMarkdownApiResult(testName);
    const editor = await createEditor({ content: html });

    expect(toMarkdown(editor.state.doc)).toBe(markdown);
  });
});
