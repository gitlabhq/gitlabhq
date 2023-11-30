import MockAdapter from 'axios-mock-adapter';
import { Emitter } from 'monaco-editor';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import waitForPromises from 'helpers/wait_for_promises';
import EditBlob from '~/blob_edit/edit_blob';
import { SourceEditorExtension } from '~/editor/extensions/source_editor_extension_base';
import { FileTemplateExtension } from '~/editor/extensions/source_editor_file_template_ext';
import { EditorMarkdownExtension } from '~/editor/extensions/source_editor_markdown_ext';
import { SecurityPolicySchemaExtension } from '~/editor/extensions/source_editor_security_policy_schema_ext';
import { EditorMarkdownPreviewExtension } from '~/editor/extensions/source_editor_markdown_livepreview_ext';
import { ToolbarExtension } from '~/editor/extensions/source_editor_toolbar_ext';
import SourceEditor from '~/editor/source_editor';
import axios from '~/lib/utils/axios_utils';

jest.mock('~/editor/source_editor');
jest.mock('~/editor/extensions/source_editor_extension_base');
jest.mock('~/editor/extensions/source_editor_file_template_ext');
jest.mock('~/editor/extensions/source_editor_markdown_ext');
jest.mock('~/editor/extensions/source_editor_markdown_livepreview_ext');
jest.mock('~/editor/extensions/source_editor_toolbar_ext');
jest.mock('~/editor/extensions/source_editor_security_policy_schema_ext');

const PREVIEW_MARKDOWN_PATH = '/foo/bar/preview_markdown';
const defaultExtensions = [
  { definition: ToolbarExtension },
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
  let blobInstance;
  let mock;
  const useMock = jest.fn(() => markdownExtensions);
  const unuseMock = jest.fn();
  const emitter = new Emitter();
  const mockInstance = {
    use: useMock,
    unuse: unuseMock,
    setValue: jest.fn(),
    getValue: jest.fn().mockReturnValue('test value'),
    focus: jest.fn(),
    onDidChangeModelLanguage: emitter.event,
    updateModelLanguage: jest.fn(),
  };
  beforeEach(() => {
    mock = new MockAdapter(axios);
    setHTMLFixture(`
      <div class="js-edit-mode-pane"></div>
      <div class="js-edit-mode"><a href="#write">Write</a><a href="#preview">Preview</a></div>
      <form class="js-edit-blob-form">
        <div id="file_path"></div>
        <div id="editor"></div>
        <textarea id="file-content"></textarea>
      </form>
    `);
    jest.spyOn(SourceEditor.prototype, 'createInstance').mockReturnValue(mockInstance);
  });
  afterEach(() => {
    mock.restore();
    unuseMock.mockClear();
    useMock.mockClear();
    resetHTMLFixture();
  });

  const editorInst = ({ isMarkdown = false, isSecurityPolicy = false }) => {
    blobInstance = new EditBlob({
      isMarkdown,
      previewMarkdownPath: PREVIEW_MARKDOWN_PATH,
      filePath: isSecurityPolicy ? '.gitlab/security-policies/policy.yml' : '',
      projectPath: 'path/to/project',
    });
    return blobInstance;
  };

  const initEditor = async ({ isMarkdown = false, isSecurityPolicy = false } = {}) => {
    editorInst({ isMarkdown, isSecurityPolicy });
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
      await initEditor({ isMarkdown: true });
      expect(useMock).toHaveBeenCalledTimes(2);
      expect(useMock.mock.calls[1]).toEqual([markdownExtensions]);
    });

    it('correctly handles switching from markdown and un-uses markdown extensions', async () => {
      await initEditor({ isMarkdown: true });
      expect(unuseMock).not.toHaveBeenCalled();
      await emitter.fire({ newLanguage: 'plaintext', oldLanguage: 'markdown' });
      expect(unuseMock).toHaveBeenCalledWith(markdownExtensions);
    });

    it('correctly handles switching from non-markdown to markdown extensions', async () => {
      const mdSpy = jest.fn();
      await initEditor();
      blobInstance.fetchMarkdownExtension = mdSpy;
      expect(mdSpy).not.toHaveBeenCalled();
      await emitter.fire({ newLanguage: 'markdown', oldLanguage: 'plaintext' });
      expect(mdSpy).toHaveBeenCalled();
    });
  });

  describe('Security Policy Yaml', () => {
    it('does not load SecurityPolicySchemaExtension by default', async () => {
      await initEditor();
      expect(SecurityPolicySchemaExtension).not.toHaveBeenCalled();
    });

    it('loads SecurityPolicySchemaExtension only for the security policies yml', async () => {
      await initEditor({ isSecurityPolicy: true });
      expect(useMock).toHaveBeenCalledTimes(2);
      expect(useMock.mock.calls[1]).toEqual([[{ definition: SecurityPolicySchemaExtension }]]);
    });
  });

  describe('correctly handles toggling the live-preview panel for different file types', () => {
    it.each`
      desc                                  | isMarkdown | isPreviewOpened | tabToClick    | shouldOpenPreview | shouldClosePreview | expectedDesc
      ${'not markdown with preview closed'} | ${false}   | ${false}        | ${'#write'}   | ${false}          | ${false}           | ${'not toggle preview'}
      ${'not markdown with preview closed'} | ${false}   | ${false}        | ${'#preview'} | ${false}          | ${false}           | ${'not toggle preview'}
      ${'markdown with preview closed'}     | ${true}    | ${false}        | ${'#write'}   | ${false}          | ${false}           | ${'not toggle preview'}
      ${'markdown with preview closed'}     | ${true}    | ${false}        | ${'#preview'} | ${true}           | ${false}           | ${'open preview'}
      ${'markdown with preview opened'}     | ${true}    | ${true}         | ${'#write'}   | ${false}          | ${true}            | ${'close preview'}
      ${'markdown with preview opened'}     | ${true}    | ${true}         | ${'#preview'} | ${false}          | ${false}           | ${'not toggle preview'}
    `(
      'when $desc, clicking $tabToClick should $expectedDesc',
      async ({
        isMarkdown,
        isPreviewOpened,
        tabToClick,
        shouldOpenPreview,
        shouldClosePreview,
      }) => {
        const fire = jest.fn();
        SourceEditor.prototype.createInstance = jest.fn().mockReturnValue({
          ...mockInstance,
          markdownPreview: {
            eventEmitter: {
              fire,
            },
          },
        });
        await initEditor({ isMarkdown });
        blobInstance.markdownLivePreviewOpened = isPreviewOpened;
        const elToClick = document.querySelector(`a[href='${tabToClick}']`);
        elToClick.dispatchEvent(new Event('click'));

        if (shouldOpenPreview || shouldClosePreview) {
          expect(fire).toHaveBeenCalled();
        } else {
          expect(fire).not.toHaveBeenCalled();
        }
      },
    );
  });

  it('adds trailing newline to the blob content on submit', async () => {
    const form = document.querySelector('.js-edit-blob-form');
    const fileContentEl = document.getElementById('file-content');

    await initEditor();

    form.dispatchEvent(new Event('submit'));

    expect(fileContentEl.value).toBe('test value\n');
  });
});
