import EditBlob from '~/blob_edit/edit_blob';
import EditorLite from '~/editor/editor_lite';
import MarkdownExtension from '~/editor/editor_markdown_ext';
import FileTemplateExtension from '~/editor/editor_file_template_ext';

jest.mock('~/editor/editor_lite');
jest.mock('~/editor/editor_markdown_ext');

describe('Blob Editing', () => {
  const mockInstance = 'foo';
  beforeEach(() => {
    setFixtures(
      `<div class="js-edit-blob-form"><div id="file_path"></div><div id="editor"></div><input id="file-content"></div>`,
    );
    jest.spyOn(EditorLite.prototype, 'createInstance').mockReturnValue(mockInstance);
  });

  const initEditor = (isMarkdown = false) => {
    return new EditBlob({
      isMarkdown,
      monacoEnabled: true,
    });
  };

  it('loads FileTemplateExtension by default', async () => {
    await initEditor();
    expect(EditorLite.prototype.use).toHaveBeenCalledWith(
      expect.arrayContaining([FileTemplateExtension]),
      mockInstance,
    );
  });

  describe('Markdown', () => {
    it('does not load MarkdownExtension by default', async () => {
      await initEditor();
      expect(EditorLite.prototype.use).not.toHaveBeenCalledWith(
        expect.arrayContaining([MarkdownExtension]),
        mockInstance,
      );
    });

    it('loads MarkdownExtension only for the markdown files', async () => {
      await initEditor(true);
      expect(EditorLite.prototype.use).toHaveBeenCalledWith(
        [MarkdownExtension, FileTemplateExtension],
        mockInstance,
      );
    });
  });
});
