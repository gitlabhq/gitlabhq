import MockAdapter from 'axios-mock-adapter';
import { Emitter } from 'monaco-editor';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import waitForPromises from 'helpers/wait_for_promises';
import EditBlob from '~/blob_edit/edit_blob';
import { BLOB_EDITOR_ERROR } from '~/blob_edit/constants';
import { SourceEditorExtension } from '~/editor/extensions/source_editor_extension_base';
import { FileTemplateExtension } from '~/editor/extensions/source_editor_file_template_ext';
import { EditorMarkdownExtension } from '~/editor/extensions/source_editor_markdown_ext';
import { SecurityPolicySchemaExtension } from '~/editor/extensions/source_editor_security_policy_schema_ext';
import { EditorMarkdownPreviewExtension } from '~/editor/extensions/source_editor_markdown_livepreview_ext';
import { ToolbarExtension } from '~/editor/extensions/source_editor_toolbar_ext';
import SourceEditor from '~/editor/source_editor';
import axios from '~/lib/utils/axios_utils';
import { addEditorMarkdownListeners } from '~/lib/utils/text_markdown';
import { TEST_HOST } from 'helpers/test_constants';
import {
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
  HTTP_STATUS_OK,
  HTTP_STATUS_PAYLOAD_TOO_LARGE,
} from '~/lib/utils/http_status';
import { visitUrl } from '~/lib/utils/url_utility';
import { createAlert } from '~/alert';
import Api from '~/api';
import { createDynamicHeightManager } from '~/vue_shared/utils/dynamic_height';

jest.mock('~/api', () => ({ getRawFile: jest.fn().mockResolvedValue({ data: 'raw content' }) }));
jest.mock('~/editor/source_editor');
jest.mock('~/editor/extensions/source_editor_extension_base');
jest.mock('~/editor/extensions/source_editor_file_template_ext');
jest.mock('~/editor/extensions/source_editor_markdown_ext');
jest.mock('~/editor/extensions/source_editor_markdown_livepreview_ext');
jest.mock('~/editor/extensions/source_editor_toolbar_ext');
jest.mock('~/editor/extensions/source_editor_security_policy_schema_ext');
jest.mock('~/lib/utils/url_utility');
jest.mock('~/lib/utils/text_markdown');
jest.mock('~/alert');
jest.mock('~/vue_shared/utils/dynamic_height', () => ({
  createDynamicHeightManager: jest.fn().mockReturnValue({
    destroy: jest.fn(),
  }),
}));

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
  const projectId = '123';
  const filePath = 'path/to/file.js';
  const useMock = jest.fn(() => markdownExtensions);
  const unuseMock = jest.fn();
  const valueMock = 'test value';
  const getValueMock = jest.fn().mockReturnValue('test value');
  let emitter;
  const mockInstance = {
    use: useMock,
    unuse: unuseMock,
    setValue: jest.fn(),
    getValue: getValueMock,
    focus: jest.fn(),
    updateModelLanguage: jest.fn(),
  };

  beforeEach(() => {
    emitter = new Emitter();
    mockInstance.onDidChangeModelLanguage = emitter.event;
    mock = new MockAdapter(axios);
    setHTMLFixture(`
      <div class="js-edit-mode-pane"></div>
      <div class="js-edit-mode"><a href="#write">Write</a><a href="#preview">Preview</a></div>
      <form class="js-edit-blob-form">
        <div id="file_path"></div>
        <div id="editor" data-ref="main"></div>
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
      filePath: isSecurityPolicy ? '.gitlab/security-policies/policy.yml' : filePath,
      projectPath: 'path/to/project',
      projectId,
    });
    return blobInstance;
  };

  const initEditor = async ({ isMarkdown = false, isSecurityPolicy = false } = {}) => {
    editorInst({ isMarkdown, isSecurityPolicy });
    await waitForPromises();
  };

  describe('file content', () => {
    beforeEach(() => initEditor());
    it('requests raw file content', () => {
      expect(Api.getRawFile).toHaveBeenCalledWith(
        projectId,
        filePath,
        { ref: 'main' },
        { responseType: 'text', transformResponse: expect.any(Function) },
      );
    });

    it('creates an editor instance with the raw content', () => {
      expect(SourceEditor.prototype.createInstance).toHaveBeenCalledWith(
        expect.objectContaining({
          blobContent: 'raw content',
        }),
      );
    });

    it('returns content from the editor', () => {
      expect(blobInstance.getFileContent()).toBe(valueMock);
      expect(getValueMock).toHaveBeenCalled();
    });
  });

  it('loads SourceEditorExtension and FileTemplateExtension by default', async () => {
    await initEditor();
    expect(useMock).toHaveBeenCalledWith(defaultExtensions);
  });

  describe('Markdown', () => {
    const countMarkdownExtensionLoads = () =>
      useMock.mock.calls.filter(
        ([extensions]) =>
          Array.isArray(extensions) &&
          extensions.some(({ definition }) => definition === EditorMarkdownExtension),
      ).length;

    it('does not load MarkdownExtensions by default', async () => {
      await initEditor();
      expect(countMarkdownExtensionLoads()).toBe(0);
      expect(EditorMarkdownExtension).not.toHaveBeenCalled();
      expect(EditorMarkdownPreviewExtension).not.toHaveBeenCalled();
    });

    it('loads MarkdownExtension only for the markdown files', async () => {
      await initEditor({ isMarkdown: true });
      expect(countMarkdownExtensionLoads()).toBe(1);
      expect(useMock).toHaveBeenCalledWith(markdownExtensions);
    });

    it('correctly handles switching from markdown and un-uses markdown extensions', async () => {
      await initEditor({ isMarkdown: true });
      expect(countMarkdownExtensionLoads()).toBe(1);
      await emitter.fire({ newLanguage: 'plaintext', oldLanguage: 'markdown' });
      expect(unuseMock).toHaveBeenCalledWith(markdownExtensions);
    });

    it('correctly handles switching from non-markdown to markdown extensions', async () => {
      await initEditor();
      expect(countMarkdownExtensionLoads()).toBe(0);
      await emitter.fire({ newLanguage: 'markdown', oldLanguage: 'plaintext' });
      await waitForPromises();
      expect(countMarkdownExtensionLoads()).toBe(1);
    });

    it('does not load markdown extensions again when they are already loaded', async () => {
      const loadSpy = jest.spyOn(EditBlob.prototype, 'loadMarkdownExtensions');
      await initEditor({ isMarkdown: true });
      expect(countMarkdownExtensionLoads()).toBe(1);
      expect(addEditorMarkdownListeners).toHaveBeenCalledTimes(1);

      await emitter.fire({ newLanguage: 'markdown', oldLanguage: 'plaintext' });
      await waitForPromises();

      expect(loadSpy).toHaveBeenCalledTimes(1);
      expect(countMarkdownExtensionLoads()).toBe(1);
      expect(addEditorMarkdownListeners).toHaveBeenCalledTimes(1);
    });

    it('reloads markdown extensions after they have been unloaded', async () => {
      await initEditor({ isMarkdown: true });
      expect(countMarkdownExtensionLoads()).toBe(1);

      await emitter.fire({ newLanguage: 'plaintext', oldLanguage: 'markdown' });
      await emitter.fire({ newLanguage: 'markdown', oldLanguage: 'plaintext' });
      await waitForPromises();

      expect(countMarkdownExtensionLoads()).toBe(2);
    });

    it('does not start a second load while one is in progress', async () => {
      const loadSpy = jest.spyOn(EditBlob.prototype, 'loadMarkdownExtensions');
      await initEditor();
      expect(countMarkdownExtensionLoads()).toBe(0);

      // Fire twice without waiting, so the second event arrives while
      // the first load is still in progress.
      emitter.fire({ newLanguage: 'markdown', oldLanguage: 'plaintext' });
      emitter.fire({ newLanguage: 'markdown', oldLanguage: 'plaintext' });
      await waitForPromises();

      expect(loadSpy).toHaveBeenCalledTimes(1);
      expect(countMarkdownExtensionLoads()).toBe(1);
    });

    it('does not use markdown extensions when switched away during load, and reloads them after', async () => {
      await initEditor();

      // Switch to markdown and away again without waiting,
      // so the second event arrives while the extensions are still loading.
      emitter.fire({ newLanguage: 'markdown', oldLanguage: 'plaintext' });
      emitter.fire({ newLanguage: 'plaintext', oldLanguage: 'markdown' });
      await waitForPromises();

      expect(unuseMock).not.toHaveBeenCalled();
      expect(addEditorMarkdownListeners).not.toHaveBeenCalled();
      expect(countMarkdownExtensionLoads()).toBe(0);

      // Switching back after the stale load was skipped loads them again.
      await emitter.fire({ newLanguage: 'markdown', oldLanguage: 'plaintext' });
      await waitForPromises();

      expect(countMarkdownExtensionLoads()).toBe(1);
    });

    it('uses markdown extensions only once when switched back to markdown during load', async () => {
      await initEditor();

      // Switch to markdown, away, and back again without waiting,
      // so both loads are in progress at the same time.
      emitter.fire({ newLanguage: 'markdown', oldLanguage: 'plaintext' });
      emitter.fire({ newLanguage: 'plaintext', oldLanguage: 'markdown' });
      emitter.fire({ newLanguage: 'markdown', oldLanguage: 'plaintext' });
      await waitForPromises();

      expect(countMarkdownExtensionLoads()).toBe(1);
    });

    // Verified via addEditorMarkdownListeners: use() calls are recorded
    // even when they throw, so countMarkdownExtensionLoads cannot
    // distinguish a failed load from a successful one.
    it('recovers after a failed load', async () => {
      await initEditor();
      useMock.mockImplementationOnce(() => {
        throw new Error('loading failed');
      });

      await emitter.fire({ newLanguage: 'markdown', oldLanguage: 'plaintext' });
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledTimes(1);
      expect(createAlert).toHaveBeenCalledWith({
        message: BLOB_EDITOR_ERROR,
        error: expect.any(Error),
        captureError: true,
      });
      expect(addEditorMarkdownListeners).not.toHaveBeenCalled();

      await emitter.fire({ newLanguage: 'markdown', oldLanguage: 'plaintext' });
      await waitForPromises();

      expect(addEditorMarkdownListeners).toHaveBeenCalledTimes(1);
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
            shown: isPreviewOpened,
            eventEmitter: {
              fire,
            },
          },
        });
        await initEditor({ isMarkdown });
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

  describe('submit form', () => {
    const findForm = () => document.querySelector('.js-edit-blob-form');
    const content = 'some \r\n content \n';
    const endpoint = `${TEST_HOST}/some/endpoint`;

    const setupSpec = async (method) => {
      setHTMLFixture(`
      <form class="js-edit-blob-form" data-form-method="${method}" action="${endpoint}">
        <div id="file_path"></div>
        <div id="editor"></div>
        <button class="js-submit" type="submit">Submit</button>
      </form>
    `);

      await initEditor();
      jest.spyOn(axios, method);
      findForm().dispatchEvent(new Event('submit'));
      await waitForPromises();
    };

    beforeEach(() => {
      mockInstance.getValue = jest.fn().mockReturnValue(content);
    });

    it.each(['post', 'put'])(
      'submits a "%s" request without mutating line endings',
      async (method) => {
        await setupSpec(method);

        expect(axios[method]).toHaveBeenCalledWith(endpoint, { content });
      },
    );

    it('redirects to the correct URL', async () => {
      mock.onPost(endpoint).reply(HTTP_STATUS_OK, { filePath });
      await setupSpec('post');

      expect(visitUrl).toHaveBeenCalledWith(filePath);
    });

    it('creates an alert when an error occurs', async () => {
      mock.onPost(endpoint).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
      await setupSpec('post');

      expect(createAlert).toHaveBeenCalledWith(
        expect.objectContaining({
          message: 'An error occurred editing the blob',
          captureError: true,
        }),
      );
    });
  });

  describe('handles error during preview', () => {
    const endpoint = `${TEST_HOST}/preview`;

    const setupSpec = async () => {
      await initEditor();
      const findPreviewLink = () => document.querySelector('a[href="#preview"]');
      findPreviewLink().dataset.previewUrl = endpoint;
      findPreviewLink().click();
      await waitForPromises();
    };

    it('creates an alert for file size limit exceeded', async () => {
      mock.onPost(endpoint).reply(HTTP_STATUS_PAYLOAD_TOO_LARGE);
      await setupSpec();

      expect(createAlert).toHaveBeenCalledWith(
        expect.objectContaining({
          message: 'The blob is too large to render',
        }),
      );
    });

    it('creates a generic alert for other errors', async () => {
      mock.onPost(endpoint).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
      await setupSpec();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'An error occurred previewing the blob',
      });
    });
  });

  describe('dynamic height integration', () => {
    it('initializes dynamic height manager for the editor element', async () => {
      setHTMLFixture(`
        <div class="js-edit-mode-pane"></div>
        <div class="js-edit-mode"><a href="#write">Write</a><a href="#preview">Preview</a></div>
        <form class="js-edit-blob-form">
          <div id="file_path"></div>
          <div id="editor" data-ref="main"></div>
          <textarea id="file-content"></textarea>
        </form>
      `);

      await initEditor();

      expect(createDynamicHeightManager).toHaveBeenCalledWith(document.getElementById('editor'));
    });

    it('cleans up dynamic height manager on destroy', async () => {
      setHTMLFixture(`
        <div class="js-edit-mode-pane"></div>
        <div class="js-edit-mode"><a href="#write">Write</a><a href="#preview">Preview</a></div>
        <form class="js-edit-blob-form">
          <div id="file_path"></div>
          <div id="editor" data-ref="main"></div>
          <textarea id="file-content"></textarea>
        </form>
      `);

      await initEditor();
      const mockManager = createDynamicHeightManager.mock.results[0].value;

      blobInstance.destroy();

      expect(mockManager.destroy).toHaveBeenCalled();
    });
  });

  describe('new file with content query parameter', () => {
    it('loads blob content from api when filePath is set', async () => {
      setHTMLFixture(`
      <div class="js-edit-mode-pane"></div>
      <div class="js-edit-mode"><a href="#write">Write</a><a href="#preview">Preview</a></div>
      <form class="js-edit-blob-form">
        <div id="file_path"></div>
        <div id="editor" data-ref="main">
          <pre class="editor-loading-content">ignored content</pre>
        </div>
        <textarea id="file-content"></textarea>
      </form>
    `);

      blobInstance = new EditBlob({
        isMarkdown: false,
        previewMarkdownPath: PREVIEW_MARKDOWN_PATH,
        filePath: 'path/to/file.js',
        projectPath: 'path/to/project',
        projectId,
      });

      await waitForPromises();

      expect(SourceEditor.prototype.createInstance).toHaveBeenCalledWith(
        expect.objectContaining({
          blobContent: 'raw content',
        }),
      );
    });

    it('loads blob content from content query param when filePath is not set', async () => {
      const preRenderedContent = 'hello world\nfrom query param';

      setHTMLFixture(`
      <div class="js-edit-mode-pane"></div>
      <div class="js-edit-mode"><a href="#write">Write</a><a href="#preview">Preview</a></div>
      <form class="js-edit-blob-form">
        <div id="file_path"></div>
        <div id="editor" data-ref="main">
          <pre class="editor-loading-content">${preRenderedContent}</pre>
        </div>
        <textarea id="file-content"></textarea>
      </form>
    `);

      blobInstance = new EditBlob({
        isMarkdown: false,
        previewMarkdownPath: PREVIEW_MARKDOWN_PATH,
        filePath: null,
        projectPath: 'path/to/project',
        projectId,
      });
      await waitForPromises();

      expect(Api.getRawFile).not.toHaveBeenCalled();
      expect(SourceEditor.prototype.createInstance).toHaveBeenCalledWith(
        expect.objectContaining({
          blobContent: preRenderedContent,
        }),
      );
    });
  });
});
