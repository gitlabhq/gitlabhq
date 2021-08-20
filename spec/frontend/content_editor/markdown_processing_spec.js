import { createContentEditor } from '~/content_editor';
import { loadMarkdownApiExamples, loadMarkdownApiResult } from './markdown_processing_examples';

jest.mock('~/emoji');

describe('markdown processing', () => {
  // Ensure we generate same markdown that was provided to Markdown API.
  it.each(loadMarkdownApiExamples())(
    'correctly handles %s (context: %s)',
    async (name, context, markdown) => {
      const testName = context ? `${context}_${name}` : name;
      const contentEditor = createContentEditor({
        renderMarkdown: () => loadMarkdownApiResult(testName),
      });
      await contentEditor.setSerializedContent(markdown);

      expect(contentEditor.getSerializedContent()).toBe(markdown);
    },
  );
});
