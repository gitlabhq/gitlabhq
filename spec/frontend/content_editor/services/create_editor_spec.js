import { PROVIDE_SERIALIZER_OR_RENDERER_ERROR } from '~/content_editor/constants';
import createEditor from '~/content_editor/services/create_editor';
import createMarkdownSerializer from '~/content_editor/services/markdown_serializer';

jest.mock('~/content_editor/services/markdown_serializer');

describe('content_editor/services/create_editor', () => {
  const buildMockSerializer = () => ({
    serialize: jest.fn(),
    deserialize: jest.fn(),
  });

  describe('creating an editor', () => {
    it('uses markdown serializer when a renderMarkdown function is provided', async () => {
      const renderMarkdown = () => true;
      const mockSerializer = buildMockSerializer();
      createMarkdownSerializer.mockReturnValueOnce(mockSerializer);

      await createEditor({ renderMarkdown });

      expect(createMarkdownSerializer).toHaveBeenCalledWith({ render: renderMarkdown });
    });

    it('uses custom serializer when it is provided', async () => {
      const mockSerializer = buildMockSerializer();
      const serializedContent = '**bold**';

      mockSerializer.serialize.mockReturnValueOnce(serializedContent);

      const editor = await createEditor({ serializer: mockSerializer });

      expect(editor.getSerializedContent()).toBe(serializedContent);
    });

    it('throws an error when neither a serializer or renderMarkdown fn are provided', async () => {
      await expect(createEditor()).rejects.toThrow(PROVIDE_SERIALIZER_OR_RENDERER_ERROR);
    });
  });
});
