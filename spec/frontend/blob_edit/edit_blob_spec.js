import waitForPromises from 'helpers/wait_for_promises';
import EditBlob from '~/blob_edit/edit_blob';
import EditorLite from '~/editor/editor_lite';
import { EditorMarkdownExtension } from '~/editor/editor_markdown_ext';
import { FileTemplateExtension } from '~/editor/editor_file_template_ext';

jest.mock('~/editor/editor_lite');
jest.mock('~/editor/editor_markdown_ext');
jest.mock('~/editor/editor_file_template_ext');

describe('Blob Editing', () => {
  const useMock = jest.fn();
  const mockInstance = {
    use: useMock,
    getValue: jest.fn(),
    focus: jest.fn(),
  };
  beforeEach(() => {
    setFixtures(
      `<div class="js-edit-blob-form"><div id="file_path"></div><div id="editor"></div><input id="file-content"></div>`,
    );
    jest.spyOn(EditorLite.prototype, 'createInstance').mockReturnValue(mockInstance);
  });
  afterEach(() => {
    EditorMarkdownExtension.mockClear();
    FileTemplateExtension.mockClear();
  });

  const editorInst = isMarkdown => {
    return new EditBlob({
      isMarkdown,
    });
  };

  const initEditor = async (isMarkdown = false) => {
    editorInst(isMarkdown);
    await waitForPromises();
  };

  it('loads FileTemplateExtension by default', async () => {
    await initEditor();
    expect(FileTemplateExtension).toHaveBeenCalledTimes(1);
  });

  describe('Markdown', () => {
    it('does not load MarkdownExtension by default', async () => {
      await initEditor();
      expect(EditorMarkdownExtension).not.toHaveBeenCalled();
    });

    it('loads MarkdownExtension only for the markdown files', async () => {
      await initEditor(true);
      expect(useMock).toHaveBeenCalledTimes(2);
      expect(FileTemplateExtension).toHaveBeenCalledTimes(1);
      expect(EditorMarkdownExtension).toHaveBeenCalledTimes(1);
    });
  });
});
