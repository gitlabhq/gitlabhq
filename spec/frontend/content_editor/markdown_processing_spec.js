import { createContentEditor } from '~/content_editor';
import { loadMarkdownApiExamples, loadMarkdownApiResult } from './markdown_processing_examples';

describe('markdown processing', () => {
  // Ensure we generate same markdown that was provided to Markdown API.
  it.each(loadMarkdownApiExamples())('correctly handles %s', async (testName, markdown) => {
    const { html } = loadMarkdownApiResult(testName);
    const contentEditor = createContentEditor({ renderMarkdown: () => html });
    await contentEditor.setSerializedContent(markdown);

    expect(contentEditor.getSerializedContent()).toBe(markdown);
  });
});
