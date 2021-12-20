import waitForPromises from 'helpers/wait_for_promises';
import EditBlob from '~/blob_edit/edit_blob';
import { SourceEditorExtension } from '~/editor/extensions/source_editor_extension_base';
import { FileTemplateExtension } from '~/editor/extensions/source_editor_file_template_ext';
import { EditorMarkdownExtension } from '~/editor/extensions/source_editor_markdown_ext';
import { EditorMarkdownPreviewExtension } from '~/editor/extensions/source_editor_markdown_livepreview_ext';
import SourceEditor from '~/editor/source_editor';

jest.mock('~/editor/source_editor');
jest.mock('~/editor/extensions/source_editor_extension_base');
jest.mock('~/editor/extensions/source_editor_file_template_ext');
jest.mock('~/editor/extensions/source_editor_markdown_ext');
jest.mock('~/editor/extensions/source_editor_markdown_livepreview_ext');

const PREVIEW_MARKDOWN_PATH = '/foo/bar/preview_markdown';
const defaultExtensions = [
  { definition: SourceEditorExtension },
  { definition: FileTemplateExtension },
];
const markdownExtensions = [
  { definition: EditorMarkdownExtension },
  {
    definition: EditorMarkdownPreviewExtension,
    setupOptions: { previewMarkdownPath: PREVIEW_MARKDOWN_PATH },
  },
];

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
    SourceEditorExtension.mockClear();
    EditorMarkdownExtension.mockClear();
    EditorMarkdownPreviewExtension.mockClear();
    FileTemplateExtension.mockClear();
  });

  const editorInst = (isMarkdown) => {
    return new EditBlob({
      isMarkdown,
      previewMarkdownPath: PREVIEW_MARKDOWN_PATH,
    });
  };

  const initEditor = async (isMarkdown = false) => {
    editorInst(isMarkdown);
    await waitForPromises();
  };

  it('loads SourceEditorExtension and FileTemplateExtension by default', async () => {
    await initEditor();
    expect(useMock).toHaveBeenCalledWith(defaultExtensions);
  });

  describe('Markdown', () => {
    it('does not load MarkdownExtensions by default', async () => {
      await initEditor();
      expect(EditorMarkdownExtension).not.toHaveBeenCalled();
      expect(EditorMarkdownPreviewExtension).not.toHaveBeenCalled();
    });

    it('loads MarkdownExtension only for the markdown files', async () => {
      await initEditor(true);
      expect(useMock).toHaveBeenCalledTimes(2);
      expect(useMock.mock.calls[1]).toEqual([markdownExtensions]);
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
