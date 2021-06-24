import { createContentEditor } from '~/content_editor';
import { loadMarkdownApiExamples, loadMarkdownApiResult } from './markdown_processing_examples';

describe('markdown processing', () => {
  // Ensure we generate same markdown that was provided to Markdown API.
  it.each(loadMarkdownApiExamples())(
    'correctly handles %s (context: %s)',
    async (name, context, markdown) => {
      const testName = context ? `${context}_${name}` : name;
      const { html, body } = loadMarkdownApiResult(testName);
      const contentEditor = createContentEditor({ renderMarkdown: () => html || body });
      await contentEditor.setSerializedContent(markdown);

      expect(contentEditor.getSerializedContent()).toBe(markdown);
    },
  );
});
