import MockAdapter from 'axios-mock-adapter';
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
const PREVIEW_ENDPOINT = `${TEST_HOST}/preview`;
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
  const mockInstance = {
    use: useMock,
    unuse: unuseMock,
    setValue: jest.fn(),
    getValue: getValueMock,
    focus: jest.fn(),
    updateModelLanguage: jest.fn(),
  };

  const setEditorFixture = ({ editorContent = '' } = {}) => {
    setHTMLFixture(`
      <div class="js-edit-mode"><a href="#editor">Write</a><a href="#preview">Preview</a></div>
      <form class="js-edit-blob-form">
        <input id="file_path" />
        <div class="js-edit-mode-pane" id="editor" data-ref="main">${editorContent}</div>
        <div class="js-edit-mode-pane" id="preview"></div>
      </form>
    `);
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    setEditorFixture();
    jest.spyOn(SourceEditor.prototype, 'createInstance').mockReturnValue(mockInstance);
  });
  afterEach(() => {
    mock.restore();
    unuseMock.mockClear();
    useMock.mockClear();
    resetHTMLFixture();
  });

  const editorInst = ({ isSecurityPolicy = false }) => {
    blobInstance = new EditBlob({
      previewMarkdownPath: PREVIEW_MARKDOWN_PATH,
      filePath: isSecurityPolicy ? '.gitlab/security-policies/policy.yml' : filePath,
      projectPath: 'path/to/project',
      projectId,
    });
    return blobInstance;
  };

  const initEditor = async ({ isSecurityPolicy = false } = {}) => {
    editorInst({ isSecurityPolicy });
    await waitForPromises();
  };

  // The new file page has a file name input instead of a file path input,
  // no Write/Preview tabs, and no filePath option (nothing to fetch).
  const initNewFilePage = async ({ editorContent = '' } = {}) => {
    setHTMLFixture(`
      <form class="js-edit-blob-form">
        <input id="file_name" />
        <div class="js-edit-mode-pane" id="editor" data-ref="main">${editorContent}</div>
        <div class="js-edit-mode-pane" id="preview"></div>
      </form>
    `);
    blobInstance = new EditBlob({
      previewMarkdownPath: PREVIEW_MARKDOWN_PATH,
      projectPath: 'path/to/project',
      projectId,
    });
    await waitForPromises();
  };

  const findFileNameInput = () =>
    document.getElementById('file_path') || document.getElementById('file_name');

  const setFileName = (value) => {
    findFileNameInput().value = value;
  };

  // Fires a single input event, like one keystroke, without waiting,
  // so any load it triggers is still in flight when the test continues.
  // Call it back-to-back to simulate typing.
  const startRename = (value) => {
    const input = findFileNameInput();
    input.value = value;
    input.dispatchEvent(new Event('input'));
  };

  const renameFile = async (value) => {
    startRename(value);
    await waitForPromises();
  };

  const clickTab = async (tabToClick) => {
    document.querySelector(`a[href='${tabToClick}']`).click();
    await waitForPromises();
  };

  const findPane = (id) => document.querySelector(`.js-edit-mode-pane${id}`);

  const expectEditorPaneVisible = () => {
    expect(findPane('#editor').style.display).not.toBe('none');
    expect(findPane('#preview').style.display).toBe('none');
  };

  const expectPreviewPaneVisible = () => {
    expect(findPane('#editor').style.display).toBe('none');
    expect(findPane('#preview').style.display).not.toBe('none');
  };

  const stubPreviewEndpoint = () => {
    mock.onPost(PREVIEW_ENDPOINT).reply(HTTP_STATUS_OK, '<div>rendered</div>');
    document.querySelector(`a[href='#preview']`).dataset.previewUrl = PREVIEW_ENDPOINT;
  };

  const findPreviewRequest = () => mock.history.post.find(({ url }) => url === PREVIEW_ENDPOINT);

  const expectPreviewPaneRendered = (payload) => {
    const previewRequest = findPreviewRequest();
    expect(previewRequest).toBeDefined();
    expect(JSON.parse(previewRequest.data)).toEqual(payload);
    expect(findPane('#preview').innerHTML).toContain('rendered');
    expectPreviewPaneVisible();
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

  it('keeps the editor model language in sync with the file name', async () => {
    setFileName('index.js');
    await initEditor();

    expect(mockInstance.updateModelLanguage).toHaveBeenCalledWith('index.js');

    await renameFile('index.ts');

    expect(mockInstance.updateModelLanguage).toHaveBeenLastCalledWith('index.ts');
  });

  describe('Markdown', () => {
    const countMarkdownExtensionInstalls = () =>
      useMock.mock.calls.filter(
        ([extensions]) =>
          Array.isArray(extensions) &&
          extensions.some(({ definition }) => definition === EditorMarkdownExtension),
      ).length;

    it('does not install markdown extensions by default', async () => {
      await initEditor();
      expect(countMarkdownExtensionInstalls()).toBe(0);
      expect(EditorMarkdownExtension).not.toHaveBeenCalled();
      expect(EditorMarkdownPreviewExtension).not.toHaveBeenCalled();
    });

    it('installs markdown extensions only once for a pre-filled markdown file name', async () => {
      setFileName('README.md');
      await initEditor();

      expect(countMarkdownExtensionInstalls()).toBe(1);
      expect(useMock).toHaveBeenCalledWith(markdownExtensions);
    });

    it.each`
      desc                                         | to
      ${'when renamed to a markdown file'}         | ${'README.md'}
      ${'when renamed to .rmd, unknown to Monaco'} | ${'README.rmd'}
    `('installs markdown extensions $desc', async ({ to }) => {
      setFileName('README.rst');
      await initEditor();
      expect(countMarkdownExtensionInstalls()).toBe(0);

      await renameFile(to);

      expect(countMarkdownExtensionInstalls()).toBe(1);
    });

    it.each`
      desc                                     | from
      ${'when renamed to a non-markdown file'} | ${'README.md'}
      ${'when renamed away from .rmd'}         | ${'README.rmd'}
    `('uninstalls markdown extensions $desc', async ({ from }) => {
      setFileName(from);
      await initEditor();
      expect(countMarkdownExtensionInstalls()).toBe(1);

      await renameFile('README.rst');

      expect(unuseMock).toHaveBeenCalledWith(markdownExtensions);
    });

    it('does nothing when renamed to another non-markdown file', async () => {
      setFileName('README.rst');
      await initEditor();
      expect(countMarkdownExtensionInstalls()).toBe(0);

      await renameFile('README.org');

      expect(countMarkdownExtensionInstalls()).toBe(0);
      expect(unuseMock).not.toHaveBeenCalled();
    });

    it('does not reinstall markdown extensions when renamed to another markdown file extension', async () => {
      const loadSpy = jest.spyOn(EditBlob.prototype, 'loadMarkdownExtensions');
      setFileName('README.md');
      await initEditor();
      expect(countMarkdownExtensionInstalls()).toBe(1);
      expect(addEditorMarkdownListeners).toHaveBeenCalledTimes(1);

      await renameFile('README.markdown');

      expect(loadSpy).toHaveBeenCalledTimes(1);
      expect(countMarkdownExtensionInstalls()).toBe(1);
      expect(addEditorMarkdownListeners).toHaveBeenCalledTimes(1);
    });

    it('installs markdown extensions again when renamed away and back', async () => {
      setFileName('README.md');
      await initEditor();
      expect(countMarkdownExtensionInstalls()).toBe(1);

      await renameFile('README.rst');
      await renameFile('README.md');

      expect(countMarkdownExtensionInstalls()).toBe(2);
    });

    describe('starting from a non-markdown file', () => {
      beforeEach(async () => {
        setFileName('README.rst');
        await initEditor();
      });

      it('does not start a second load while one is in progress', async () => {
        const loadSpy = jest.spyOn(EditBlob.prototype, 'loadMarkdownExtensions');

        // Type two markdown names (.mkd, then .mkdn) without waiting,
        // so the second keystroke arrives while the first load is still in flight.
        startRename('README.mkd');
        startRename('README.mkdn');
        await waitForPromises();

        expect(loadSpy).toHaveBeenCalledTimes(1);
        expect(countMarkdownExtensionInstalls()).toBe(1);
      });

      it('does not install markdown extensions when the file name leaves markdown during load, and installs them once it returns', async () => {
        // Type into markdown and past it without waiting,
        // so the next keystroke arrives while the load is still in flight.
        startRename('README.md');
        startRename('README.mde');
        await waitForPromises();

        expect(unuseMock).not.toHaveBeenCalled();
        expect(addEditorMarkdownListeners).not.toHaveBeenCalled();
        expect(countMarkdownExtensionInstalls()).toBe(0);

        // Renaming back after the stale load was skipped loads them again.
        await renameFile('README.md');

        expect(countMarkdownExtensionInstalls()).toBe(1);
      });

      it('installs markdown extensions only once when the file name returns to markdown during load', async () => {
        // Type into markdown, past it, and backspace to it again without waiting,
        // so both loads are in flight at the same time.
        startRename('README.md');
        startRename('README.mde');
        startRename('README.md');
        await waitForPromises();

        expect(countMarkdownExtensionInstalls()).toBe(1);
      });

      // Verified via addEditorMarkdownListeners: use() calls are recorded
      // even when they throw, so countMarkdownExtensionInstalls cannot
      // distinguish a failed load from a successful one.
      it('installs markdown extensions again after a failed load when renamed away and back', async () => {
        useMock.mockImplementationOnce(() => {
          throw new Error('loading failed');
        });

        await renameFile('README.md');

        expect(createAlert).toHaveBeenCalledTimes(1);
        expect(createAlert).toHaveBeenCalledWith({
          message: BLOB_EDITOR_ERROR,
          error: expect.any(Error),
          captureError: true,
        });
        expect(addEditorMarkdownListeners).not.toHaveBeenCalled();

        await renameFile('README.rst');
        await renameFile('README.md');

        expect(addEditorMarkdownListeners).toHaveBeenCalledTimes(1);
      });
    });

    describe('on the new file page', () => {
      it('installs and uninstalls markdown extensions using the file name input', async () => {
        await initNewFilePage();
        expect(countMarkdownExtensionInstalls()).toBe(0);

        await renameFile('README.md');
        expect(countMarkdownExtensionInstalls()).toBe(1);

        await renameFile('README.rst');
        expect(unuseMock).toHaveBeenCalledWith(markdownExtensions);
      });
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
    const expectFallbackToPreviewPane = (fire, previewFilePath) => {
      expect(fire).not.toHaveBeenCalled();
      expectPreviewPaneRendered({ content: valueMock, file_path: previewFilePath });
    };

    const mockEditorWithPreview = ({ shown = false } = {}) => {
      const fire = jest.fn();
      jest.spyOn(SourceEditor.prototype, 'createInstance').mockReturnValue({
        ...mockInstance,
        markdownPreview: {
          shown,
          eventEmitter: {
            fire,
          },
        },
      });
      return fire;
    };

    it.each`
      fileType                     | fileName        | previewShown | tabToClick    | expectedFireCount
      ${'non-markdown'}            | ${'README.rst'} | ${false}     | ${'#editor'}  | ${0}
      ${'non-markdown'}            | ${'README.rst'} | ${false}     | ${'#preview'} | ${0}
      ${'markdown'}                | ${'README.md'}  | ${false}     | ${'#editor'}  | ${0}
      ${'markdown'}                | ${'README.md'}  | ${false}     | ${'#preview'} | ${1}
      ${'.rmd, unknown to Monaco'} | ${'README.rmd'} | ${false}     | ${'#preview'} | ${1}
      ${'markdown'}                | ${'README.md'}  | ${true}      | ${'#editor'}  | ${1}
      ${'markdown'}                | ${'README.md'}  | ${true}      | ${'#preview'} | ${0}
    `(
      'when the file type is $fileType (preview shown: $previewShown), clicking $tabToClick fires preview toggle $expectedFireCount time(s)',
      async ({ fileName, previewShown, tabToClick, expectedFireCount }) => {
        const fire = mockEditorWithPreview({ shown: previewShown });
        setFileName(fileName);
        await initEditor();
        await clickTab(tabToClick);

        expect(fire).toHaveBeenCalledTimes(expectedFireCount);
      },
    );

    describe('when the file is renamed mid-edit', () => {
      let fire;

      beforeEach(() => {
        fire = mockEditorWithPreview();
      });

      it('opens the preview pane instead of the live preview when renamed away from markdown', async () => {
        stubPreviewEndpoint();
        setFileName('README.md');
        await initEditor();

        await renameFile('README.rst');
        await clickTab('#preview');

        expectFallbackToPreviewPane(fire, 'README.rst');
      });

      describe('starting from a non-markdown file', () => {
        beforeEach(async () => {
          setFileName('README.rst');
          await initEditor();
        });

        it('switches the preview tab to the live preview when renamed to markdown', async () => {
          await renameFile('README.md');
          await clickTab('#preview');

          expect(fire).toHaveBeenCalled();
          expectEditorPaneVisible();
        });

        it('falls back to the preview pane while markdown extensions are still loading', async () => {
          stubPreviewEndpoint();

          // Rename without waiting, so the load is still in flight on click.
          startRename('README.md');
          await clickTab('#preview');

          expectFallbackToPreviewPane(fire, 'README.md');
        });

        it('falls back to the preview pane after markdown extensions failed to load', async () => {
          stubPreviewEndpoint();
          useMock.mockImplementationOnce(() => {
            throw new Error('loading failed');
          });

          await renameFile('README.md');
          await clickTab('#preview');

          expectFallbackToPreviewPane(fire, 'README.md');
        });

        describe('with the preview pane shown before the rename', () => {
          beforeEach(async () => {
            stubPreviewEndpoint();

            // Show the preview pane, which hides the editor pane
            await clickTab('#preview');

            await renameFile('README.md');
          });

          it('starts with the editor pane hidden by the preview pane', () => {
            expectPreviewPaneVisible();
          });

          it('restores the editor pane when clicking the write tab', async () => {
            await clickTab('#editor');

            expect(fire).not.toHaveBeenCalled();
            expectEditorPaneVisible();
          });

          it('restores the editor pane and opens the live preview when clicking the preview tab', async () => {
            await clickTab('#preview');

            expect(fire).toHaveBeenCalled();
            expectEditorPaneVisible();
          });
        });
      });
    });
  });

  describe('submit form', () => {
    const findForm = () => document.querySelector('.js-edit-blob-form');
    const content = 'some \r\n content \n';
    const endpoint = `${TEST_HOST}/some/endpoint`;

    const setupSpec = async (method) => {
      setHTMLFixture(`
      <form class="js-edit-blob-form" data-form-method="${method}" action="${endpoint}">
        <input id="file_path" />
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

    afterEach(() => {
      mockInstance.getValue = getValueMock;
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
    const setupSpec = async () => {
      await initEditor();
      const findPreviewLink = () => document.querySelector('a[href="#preview"]');
      findPreviewLink().dataset.previewUrl = PREVIEW_ENDPOINT;
      findPreviewLink().click();
      await waitForPromises();
    };

    it('creates an alert for file size limit exceeded', async () => {
      mock.onPost(PREVIEW_ENDPOINT).reply(HTTP_STATUS_PAYLOAD_TOO_LARGE);
      await setupSpec();

      expect(createAlert).toHaveBeenCalledWith(
        expect.objectContaining({
          message: 'The blob is too large to render',
        }),
      );
    });

    it('creates a generic alert for other errors', async () => {
      mock.onPost(PREVIEW_ENDPOINT).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
      await setupSpec();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'An error occurred previewing the blob',
      });
    });
  });

  describe('preview request', () => {
    beforeEach(async () => {
      stubPreviewEndpoint();
      setFileName('README.rst');
      await initEditor();
    });

    it('renders the preview using the submitted file path', async () => {
      await clickTab('#preview');

      expectPreviewPaneRendered({
        content: valueMock,
        file_path: 'README.rst',
      });
    });

    it('omits the file path when the file name input is absent', async () => {
      // Stands in for the race where the tab is clicked before the input is wired up.
      findFileNameInput().remove();
      await clickTab('#preview');

      expectPreviewPaneRendered({
        content: valueMock,
      });
    });
  });

  describe('dynamic height integration', () => {
    it('initializes dynamic height manager for the editor element', async () => {
      await initEditor();

      expect(createDynamicHeightManager).toHaveBeenCalledWith(document.getElementById('editor'));
    });

    it('cleans up dynamic height manager on destroy', async () => {
      await initEditor();
      const mockManager = createDynamicHeightManager.mock.results[0].value;

      blobInstance.destroy();

      expect(mockManager.destroy).toHaveBeenCalled();
    });
  });

  describe('new file with content query parameter', () => {
    it('loads blob content from api when filePath is set', async () => {
      setEditorFixture({
        editorContent: '<pre class="editor-loading-content">ignored content</pre>',
      });

      blobInstance = new EditBlob({
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

      await initNewFilePage({
        editorContent: `<pre class="editor-loading-content">${preRenderedContent}</pre>`,
      });

      expect(Api.getRawFile).not.toHaveBeenCalled();
      expect(SourceEditor.prototype.createInstance).toHaveBeenCalledWith(
        expect.objectContaining({
          blobContent: preRenderedContent,
        }),
      );
    });
  });
});
