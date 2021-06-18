import waitForPromises from 'helpers/wait_for_promises';
import EditBlob from '~/blob_edit/edit_blob';
import { FileTemplateExtension } from '~/editor/extensions/source_editor_file_template_ext';
import { EditorMarkdownExtension } from '~/editor/extensions/source_editor_markdown_ext';
import SourceEditor from '~/editor/source_editor';

jest.mock('~/editor/source_editor');
jest.mock('~/editor/extensions/source_editor_markdown_ext');
jest.mock('~/editor/extensions/source_editor_file_template_ext');

describe('Blob Editing', () => {
  const useMock = jest.fn();
  const mockInstance = {
    use: useMock,
    setValue: jest.fn(),
    getValue: jest.fn().mockReturnValue('test value'),
    focus: jest.fn(),
  };
  beforeEach(() => {
    setFixtures(`
      <form class="js-edit-blob-form">
        <div id="file_path"></div>
        <div id="editor"></div>
        <textarea id="file-content"></textarea>
      </form>
    `);
    jest.spyOn(SourceEditor.prototype, 'createInstance').mockReturnValue(mockInstance);
  });
  afterEach(() => {
    EditorMarkdownExtension.mockClear();
    FileTemplateExtension.mockClear();
  });

  const editorInst = (isMarkdown) => {
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

  it('adds trailing newline to the blob content on submit', async () => {
    const form = document.querySelector('.js-edit-blob-form');
    const fileContentEl = document.getElementById('file-content');

    await initEditor();

    form.dispatchEvent(new Event('submit'));

    expect(fileContentEl.value).toBe('test value\n');
  });
});
