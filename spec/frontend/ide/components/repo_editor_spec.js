import { GlTab } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { editor as monacoEditor, Range } from 'monaco-editor';
import { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { shallowMount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import { stubPerformanceWebAPI } from 'helpers/performance';
import { exampleConfigs, exampleFiles } from 'jest/ide/lib/editorconfig/mock_data';
import { EDITOR_CODE_INSTANCE_FN, EDITOR_DIFF_INSTANCE_FN } from '~/editor/constants';
import { EditorMarkdownExtension } from '~/editor/extensions/source_editor_markdown_ext';
import { EditorMarkdownPreviewExtension } from '~/editor/extensions/source_editor_markdown_livepreview_ext';
import { CiSchemaExtension } from '~/editor/extensions/source_editor_ci_schema_ext';
import SourceEditor from '~/editor/source_editor';
import RepoEditor from '~/ide/components/repo_editor.vue';
import { leftSidebarViews, FILE_VIEW_MODE_PREVIEW, viewerTypes } from '~/ide/constants';
import { DEFAULT_CI_CONFIG_PATH } from '~/lib/utils/constants';
import ModelManager from '~/ide/lib/common/model_manager';
import service from '~/ide/services';
import { createStoreOptions } from '~/ide/stores';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import ContentViewer from '~/vue_shared/components/content_viewer/content_viewer.vue';
import SourceEditorInstance from '~/editor/source_editor_instance';
import { file } from '../helpers';

jest.mock('~/behaviors/markdown/render_gfm');
jest.mock('~/editor/extensions/source_editor_ci_schema_ext');

const PREVIEW_MARKDOWN_PATH = '/foo/bar/preview_markdown';
const CURRENT_PROJECT_ID = 'gitlab-org/gitlab';

const dummyFile = {
  text: {
    ...file('file.txt'),
    content: 'hello world',
    active: true,
    tempFile: true,
  },
  markdown: {
    ...file('sample.md'),
    projectId: 'namespace/project',
    path: 'sample.md',
    content: 'hello world',
    tempFile: true,
    active: true,
  },
  binary: {
    ...file('file.dat'),
    content: '🐱', // non-ascii binary content,
    tempFile: true,
    active: true,
  },
  ciConfig: {
    ...file(DEFAULT_CI_CONFIG_PATH),
    content: '',
    tempFile: true,
    active: true,
  },
  empty: {
    ...file('empty'),
    tempFile: false,
    content: '',
    raw: '',
  },
};

const createActiveFile = (props) => {
  return {
    ...dummyFile.text,
    ...props,
  };
};

const prepareStore = (state, activeFile) => {
  const localState = {
    openFiles: [activeFile],
    projects: {
      [CURRENT_PROJECT_ID]: {
        branches: {
          main: {
            name: 'main',
            commit: {
              id: 'abcdefgh',
            },
          },
        },
      },
    },
    currentProjectId: CURRENT_PROJECT_ID,
    currentBranchId: 'main',
    entries: {
      [activeFile.path]: activeFile,
    },
    previewMarkdownPath: PREVIEW_MARKDOWN_PATH,
  };
  const storeOptions = createStoreOptions();
  return new Vuex.Store({
    ...createStoreOptions(),
    state: {
      ...storeOptions.state,
      ...localState,
      ...state,
    },
  });
};

describe('RepoEditor', () => {
  let wrapper;
  let vm;
  let createInstanceSpy;
  let createDiffInstanceSpy;
  let createModelSpy;
  let applyExtensionSpy;
  let removeExtensionSpy;
  let extensionsStore;
  let store;

  const waitForEditorSetup = () =>
    new Promise((resolve) => {
      vm.$once('editorSetup', resolve);
    });

  const createComponent = async ({ state = {}, activeFile = dummyFile.text } = {}) => {
    store = prepareStore(state, activeFile);
    wrapper = shallowMount(RepoEditor, {
      store,
      propsData: {
        file: store.state.openFiles[0],
      },
      mocks: {
        ContentViewer,
      },
    });
    await waitForPromises();
    vm = wrapper.vm;
    extensionsStore = wrapper.vm.globalEditor.extensionsStore;
    jest.spyOn(vm, 'getFileData').mockResolvedValue();
    jest.spyOn(vm, 'getRawFileData').mockResolvedValue();
  };

  const findEditor = () => wrapper.find('[data-testid="editor-container"]');
  const findTabs = () => wrapper.findAllComponents(GlTab);
  const findPreviewTab = () => wrapper.find('[data-testid="preview-tab"]');

  beforeEach(() => {
    stubPerformanceWebAPI();

    createInstanceSpy = jest.spyOn(SourceEditor.prototype, EDITOR_CODE_INSTANCE_FN);
    createDiffInstanceSpy = jest.spyOn(SourceEditor.prototype, EDITOR_DIFF_INSTANCE_FN);
    createModelSpy = jest.spyOn(monacoEditor, 'createModel');
    applyExtensionSpy = jest.spyOn(SourceEditorInstance.prototype, 'use');
    removeExtensionSpy = jest.spyOn(SourceEditorInstance.prototype, 'unuse');
    jest.spyOn(service, 'getFileData').mockResolvedValue();
    jest.spyOn(service, 'getRawFileData').mockResolvedValue();
  });

  afterEach(() => {
    // create a new model each time, otherwise tests conflict with each other
    // because of same model being used in multiple tests
    monacoEditor.getModels().forEach((model) => model.dispose());
  });

  describe('default', () => {
    it.each`
      boolVal  | textVal
      ${true}  | ${'all'}
      ${false} | ${'none'}
    `('sets renderWhitespace to "$textVal"', async ({ boolVal, textVal } = {}) => {
      await createComponent({
        state: {
          renderWhitespaceInCode: boolVal,
        },
      });
      expect(vm.editorOptions.renderWhitespace).toEqual(textVal);
    });

    it('renders an ide container', async () => {
      await createComponent();
      expect(findEditor().isVisible()).toBe(true);
    });

    it('renders no tabs', async () => {
      await createComponent();
      const tabs = findTabs();

      expect(tabs).toHaveLength(0);
    });
  });

  describe('schema registration for .gitlab-ci.yml', () => {
    const setup = async (activeFile) => {
      await createComponent();
      vm.editor.registerCiSchema = jest.fn();
      if (activeFile) {
        wrapper.setProps({ file: activeFile });
      }
      await waitForPromises();
      await nextTick();
    };
    it.each`
      activeFile            | shouldUseExtension | desc
      ${dummyFile.markdown} | ${false}           | ${`file is not CI config; should NOT`}
      ${dummyFile.ciConfig} | ${true}            | ${`file is CI config; should`}
    `(
      'when the activeFile is "$activeFile", $desc use extension',
      async ({ activeFile, shouldUseExtension }) => {
        await setup(activeFile);

        if (shouldUseExtension) {
          expect(applyExtensionSpy).toHaveBeenCalledWith({
            definition: CiSchemaExtension,
          });
        } else {
          expect(applyExtensionSpy).not.toHaveBeenCalledWith({
            definition: CiSchemaExtension,
          });
        }
      },
    );
    it('stores the fetched extension and does not double-fetch the schema', async () => {
      await setup();
      expect(CiSchemaExtension).toHaveBeenCalledTimes(0);

      wrapper.setProps({ file: dummyFile.ciConfig });
      await waitForPromises();
      await nextTick();
      expect(CiSchemaExtension).toHaveBeenCalledTimes(1);
      expect(vm.CiSchemaExtension).toEqual(CiSchemaExtension);
      expect(vm.editor.registerCiSchema).toHaveBeenCalledTimes(1);

      wrapper.setProps({ file: dummyFile.markdown });
      await waitForPromises();
      await nextTick();
      expect(CiSchemaExtension).toHaveBeenCalledTimes(1);
      expect(vm.editor.registerCiSchema).toHaveBeenCalledTimes(1);

      wrapper.setProps({ file: dummyFile.ciConfig });
      await waitForPromises();
      await nextTick();
      expect(CiSchemaExtension).toHaveBeenCalledTimes(1);
      expect(vm.editor.registerCiSchema).toHaveBeenCalledTimes(2);
    });
    it('unuses the existing CI extension if the new model is not CI config', async () => {
      await setup(dummyFile.ciConfig);

      expect(removeExtensionSpy).not.toHaveBeenCalled();
      wrapper.setProps({ file: dummyFile.markdown });
      await waitForPromises();
      await nextTick();
      expect(removeExtensionSpy).toHaveBeenCalledWith(CiSchemaExtension);
    });
  });

  describe('when file is markdown', () => {
    let mock;
    let activeFile;

    beforeEach(() => {
      activeFile = dummyFile.markdown;

      mock = new MockAdapter(axios);

      mock.onPost(/(.*)\/preview_markdown/).reply(HTTP_STATUS_OK, {
        body: `<p>${dummyFile.text.content}</p>`,
      });
    });

    afterEach(() => {
      mock.restore();
    });

    describe('when files is markdown', () => {
      beforeEach(async () => {
        await createComponent({ activeFile });
      });

      it('renders an Edit and a Preview Tab', () => {
        const tabs = findTabs();

        expect(tabs).toHaveLength(2);
        expect(tabs.at(0).element.dataset.testid).toBe('edit-tab');
        expect(tabs.at(1).element.dataset.testid).toBe('preview-tab');
      });

      it('renders markdown for tempFile', async () => {
        findPreviewTab().vm.$emit('click');
        await waitForPromises();
        expect(wrapper.findComponent(ContentViewer).html()).toContain(dummyFile.text.content);
      });

      describe('when file changes to non-markdown file', () => {
        beforeEach(() => {
          wrapper.setProps({ file: dummyFile.empty });
        });

        it('should hide tabs', () => {
          expect(findTabs()).toHaveLength(0);
        });
      });
    });

    it('when not in edit mode, shows no tabs', async () => {
      await createComponent({
        state: {
          currentActivityView: leftSidebarViews.review.name,
        },
        activeFile,
      });
      expect(findTabs()).toHaveLength(0);
    });
  });

  describe('when file is binary and not raw', () => {
    beforeEach(async () => {
      const activeFile = dummyFile.binary;
      await createComponent({ activeFile });
    });

    it('does not render the IDE', () => {
      expect(findEditor().isVisible()).toBe(false);
    });

    it('does not create an instance', () => {
      expect(createInstanceSpy).not.toHaveBeenCalled();
      expect(createDiffInstanceSpy).not.toHaveBeenCalled();
    });
  });

  describe('createEditorInstance', () => {
    it.each`
      viewer              | diffInstance
      ${viewerTypes.edit} | ${undefined}
      ${viewerTypes.diff} | ${true}
      ${viewerTypes.mr}   | ${true}
    `(
      'creates instance of correct type when viewer is $viewer',
      async ({ viewer, diffInstance }) => {
        await createComponent({
          state: { viewer },
        });
        const isDiff = () => {
          return diffInstance ? { isDiff: true } : {};
        };
        expect(createInstanceSpy).toHaveBeenCalledWith(expect.objectContaining(isDiff()));
        expect(createDiffInstanceSpy).toHaveBeenCalledTimes((diffInstance && 1) || 0);
      },
    );

    it('installs the WebIDE extension', async () => {
      await createComponent();
      expect(applyExtensionSpy).toHaveBeenCalled();
      const ideExtensionApi = extensionsStore.get('EditorWebIde').api;
      Reflect.ownKeys(ideExtensionApi).forEach((fn) => {
        expect(vm.editor[fn]).toBeDefined();
        expect(vm.editor.methods[fn]).toBe('EditorWebIde');
      });
    });
  });

  describe('setupEditor', () => {
    it('creates new model on load', async () => {
      await createComponent();
      // We always create two models per file to be able to build a diff of changes
      expect(createModelSpy).toHaveBeenCalledTimes(2);
      // The model with the most recent changes is the last one
      const [content] = createModelSpy.mock.calls[1];
      expect(content).toBe(dummyFile.text.content);
    });

    it('does not create a new model on subsequent calls to setupEditor and re-uses the already-existing model', async () => {
      await createComponent();
      const existingModel = vm.model;
      createModelSpy.mockClear();

      vm.setupEditor();

      expect(createModelSpy).not.toHaveBeenCalled();
      expect(vm.model).toBe(existingModel);
    });

    it('updates state with the value of the model', async () => {
      await createComponent();
      const newContent = 'As Gregor Samsa\n awoke one morning\n';
      vm.model.setValue(newContent);

      vm.setupEditor();

      expect(vm.file.content).toBe(newContent);
    });

    it('sets head model as staged file', async () => {
      await createComponent();
      vm.modelManager.dispose();
      const addModelSpy = jest.spyOn(ModelManager.prototype, 'addModel');

      vm.$store.state.stagedFiles.push({ ...vm.file, key: 'staged' });
      vm.file.staged = true;
      vm.file.key = `unstaged-${vm.file.key}`;

      vm.setupEditor();

      expect(addModelSpy).toHaveBeenCalledWith(vm.file, vm.$store.state.stagedFiles[0]);
    });

    it.each`
      prefix          | activeFile            | viewer              | shouldHaveMarkdownExtension
      ${'Should not'} | ${dummyFile.text}     | ${viewerTypes.edit} | ${false}
      ${'Should'}     | ${dummyFile.markdown} | ${viewerTypes.edit} | ${true}
      ${'Should not'} | ${dummyFile.empty}    | ${viewerTypes.edit} | ${false}
      ${'Should not'} | ${dummyFile.text}     | ${viewerTypes.diff} | ${false}
      ${'Should not'} | ${dummyFile.markdown} | ${viewerTypes.diff} | ${false}
      ${'Should not'} | ${dummyFile.empty}    | ${viewerTypes.diff} | ${false}
      ${'Should not'} | ${dummyFile.text}     | ${viewerTypes.mr}   | ${false}
      ${'Should not'} | ${dummyFile.markdown} | ${viewerTypes.mr}   | ${false}
      ${'Should not'} | ${dummyFile.empty}    | ${viewerTypes.mr}   | ${false}
    `(
      '$prefix install markdown extension for $activeFile.name in $viewer viewer',
      async ({ activeFile, viewer, shouldHaveMarkdownExtension } = {}) => {
        await createComponent({ state: { viewer }, activeFile });

        if (shouldHaveMarkdownExtension) {
          expect(applyExtensionSpy).toHaveBeenCalledWith({
            definition: EditorMarkdownPreviewExtension,
            setupOptions: { previewMarkdownPath: PREVIEW_MARKDOWN_PATH },
          });
          // TODO: spying on extensions causes Jest to blow up, so we have to assert on
          // the public property the extension adds, as opposed to the args passed to the ctor
          expect(wrapper.vm.editor.markdownPreview.path).toBe(PREVIEW_MARKDOWN_PATH);
        } else {
          expect(applyExtensionSpy).not.toHaveBeenCalledWith(
            wrapper.vm.editor,
            expect.any(EditorMarkdownExtension),
          );
        }
      },
    );

    it('fetches the live preview extension even if markdown is not the first opened file', async () => {
      const textFile = dummyFile.text;
      const mdFile = dummyFile.markdown;
      const previewExtConfig = {
        definition: EditorMarkdownPreviewExtension,
        setupOptions: { previewMarkdownPath: PREVIEW_MARKDOWN_PATH },
      };
      await createComponent({ activeFile: textFile });
      applyExtensionSpy.mockClear();

      await wrapper.setProps({ file: mdFile });
      await waitForPromises();

      expect(applyExtensionSpy).toHaveBeenCalledWith(previewExtConfig);
    });
  });

  describe('editor tabs', () => {
    beforeEach(async () => {
      await createComponent();
    });

    it.each`
      mode        | isVisible
      ${'edit'}   | ${false}
      ${'review'} | ${false}
      ${'commit'} | ${false}
    `('tabs in $mode are $isVisible', async ({ mode, isVisible } = {}) => {
      vm.$store.state.currentActivityView = leftSidebarViews[mode].name;

      await nextTick();
      expect(wrapper.find('.nav-links').exists()).toBe(isVisible);
    });
  });

  describe('files in preview mode', () => {
    const changeViewMode = (viewMode) =>
      vm.$store.dispatch('editor/updateFileEditor', {
        path: vm.file.path,
        data: { viewMode },
      });

    beforeEach(async () => {
      await createComponent({
        activeFile: dummyFile.markdown,
      });

      changeViewMode(FILE_VIEW_MODE_PREVIEW);
      await nextTick();
    });

    it('do not show the editor', () => {
      expect(vm.showEditor).toBe(false);
      expect(findEditor().isVisible()).toBe(false);
    });
  });

  describe('initEditor', () => {
    const hideEditorAndRunFn = async () => {
      jest.clearAllMocks();
      jest.spyOn(vm, 'shouldHideEditor', 'get').mockReturnValue(true);

      vm.initEditor();
      await nextTick();
    };

    it('does not fetch file information for temp entries', async () => {
      await createComponent({
        activeFile: dummyFile.text,
      });

      expect(vm.getFileData).not.toHaveBeenCalled();
    });

    it('is being initialised for files without content even if shouldHideEditor is `true`', async () => {
      await createComponent({
        activeFile: dummyFile.empty,
      });

      await hideEditorAndRunFn();

      expect(vm.getFileData).toHaveBeenCalled();
      expect(vm.getRawFileData).toHaveBeenCalled();
    });

    it('does not initialize editor for files already with content when shouldHideEditor is `true`', async () => {
      await createComponent({
        activeFile: dummyFile.text,
      });

      await hideEditorAndRunFn();

      expect(vm.getFileData).not.toHaveBeenCalled();
      expect(vm.getRawFileData).not.toHaveBeenCalled();
      expect(createInstanceSpy).not.toHaveBeenCalled();
    });
  });

  describe('updates on file changes', () => {
    beforeEach(async () => {
      await createComponent({
        activeFile: createActiveFile({
          content: 'foo', // need to prevent full cycle of initEditor
        }),
      });
      jest.spyOn(vm, 'initEditor').mockImplementation();
    });

    it('calls removePendingTab when old file is pending', async () => {
      jest.spyOn(vm, 'shouldHideEditor', 'get').mockReturnValue(true);
      jest.spyOn(vm, 'removePendingTab').mockImplementation();

      const origFile = vm.file;
      vm.file.pending = true;
      await nextTick();

      wrapper.setProps({
        file: file('testing'),
      });
      vm.file.content = 'foo'; // need to prevent full cycle of initEditor
      await nextTick();

      expect(vm.removePendingTab).toHaveBeenCalledWith(origFile);
    });

    it('does not call initEditor if the file did not change', async () => {
      const newFile = { ...store.state.openFiles[0] };
      wrapper.setProps({
        file: newFile,
      });
      await nextTick();

      expect(vm.initEditor).not.toHaveBeenCalled();
    });

    it('calls initEditor when file key is changed', async () => {
      expect(vm.initEditor).not.toHaveBeenCalled();

      wrapper.setProps({
        file: {
          ...vm.file,
          key: 'new',
        },
      });
      await nextTick();

      expect(vm.initEditor).toHaveBeenCalled();
    });
  });

  describe('populates editor with the fetched content', () => {
    const createRemoteFile = (name) => ({
      ...file(name),
      tmpFile: false,
    });

    beforeEach(async () => {
      await createComponent();
      vm.getRawFileData.mockRestore();
    });

    it('after switching viewer from edit to diff', async () => {
      const f = createRemoteFile('newFile');
      store.state.entries[f.path] = f;
      jest.spyOn(service, 'getRawFileData').mockImplementation(() => {
        expect(vm.file.loading).toBe(true);

        // switching from edit to diff mode usually triggers editor initialization
        vm.$store.state.viewer = viewerTypes.diff;

        jest.runOnlyPendingTimers();

        return Promise.resolve('rawFileData123\n');
      });

      wrapper.setProps({
        file: f,
      });

      await waitForEditorSetup();
      expect(vm.model.getModel().getValue()).toBe('rawFileData123\n');
    });

    it('after opening multiple files at the same time', async () => {
      const fileA = createRemoteFile('fileA');
      const aContent = 'fileA-rawContent\n';
      const bContent = 'fileB-rawContent\n';
      const fileB = createRemoteFile('fileB');
      store.state.entries[fileA.path] = fileA;
      store.state.entries[fileB.path] = fileB;

      jest
        .spyOn(service, 'getRawFileData')
        .mockImplementation(() => {
          // opening fileB while the content of fileA is still being fetched
          wrapper.setProps({
            file: fileB,
          });
          return Promise.resolve(aContent);
        })
        .mockImplementationOnce(() => {
          // we delay returning fileB content
          // to make sure the editor doesn't initialize prematurely
          jest.advanceTimersByTime(30);
          return Promise.resolve(bContent);
        });

      wrapper.setProps({
        file: fileA,
      });

      await waitForEditorSetup();
      expect(vm.model.getModel().getValue()).toBe(bContent);
    });
  });

  describe('onPaste', () => {
    const setFileName = (name) =>
      createActiveFile({
        content: 'hello world\n',
        name,
        path: `foo/${name}`,
        key: 'new',
      });

    const pasteImage = () => {
      window.dispatchEvent(
        Object.assign(new Event('paste'), {
          clipboardData: {
            files: [new File(['foo'], 'foo.png', { type: 'image/png' })],
          },
        }),
      );
    };

    const watchState = (watched) =>
      new Promise((resolve) => {
        const unwatch = vm.$store.watch(watched, () => {
          unwatch();
          resolve();
        });
      });

    // Pasting an image does a lot of things like using the FileReader API,
    // so, waitForPromises isn't very reliable (and causes a flaky spec)
    // Read more about state.watch: https://vuex.vuejs.org/api/#watch
    const waitForFileContentChange = () => watchState((s) => s.entries['foo/bar.md'].content);

    beforeEach(async () => {
      await createComponent({
        state: {
          trees: {
            'gitlab-org/gitlab': { tree: [] },
          },
          currentProjectId: 'gitlab-org',
          currentBranchId: 'gitlab',
        },
        activeFile: setFileName('bar.md'),
      });

      // set cursor to line 2, column 1
      vm.editor.setSelection(new Range(2, 1, 2, 1));
      vm.editor.focus();

      jest.spyOn(vm.editor, 'hasTextFocus').mockReturnValue(true);
    });

    it('adds an image entry to the same folder for a pasted image in a markdown file', async () => {
      pasteImage();

      await waitForFileContentChange();
      expect(vm.$store.state.entries['foo/foo.png'].rawPath.startsWith('blob:')).toBe(true);
      expect(vm.$store.state.entries['foo/foo.png']).toMatchObject({
        path: 'foo/foo.png',
        type: 'blob',
        content: 'foo',
        rawPath: vm.$store.state.entries['foo/foo.png'].rawPath,
      });
    });

    it("adds a markdown image tag to the file's contents", async () => {
      pasteImage();

      await waitForFileContentChange();
      expect(vm.file.content).toBe('hello world\n![foo.png](./foo.png)');
    });

    it("does not add file to state or set markdown image syntax if the file isn't markdown", async () => {
      await wrapper.setProps({
        file: setFileName('myfile.txt'),
      });
      pasteImage();

      await waitForPromises();
      expect(vm.$store.state.entries['foo/foo.png']).toBeUndefined();
      expect(vm.file.content).toBe('hello world\n');
    });
  });

  describe('fetchEditorconfigRules', () => {
    it.each(exampleFiles)(
      'does not fetch content from remote for .editorconfig files present locally (case %#)',
      async ({ path, monacoRules }) => {
        await createComponent({
          state: {
            entries: (() => {
              const res = {};
              exampleConfigs.forEach(({ path: configPath, content }) => {
                res[configPath] = { ...file(), path: configPath, content };
              });
              return res;
            })(),
          },
          activeFile: createActiveFile({
            path,
            key: path,
            name: 'myfile.txt',
            content: 'hello world',
          }),
        });

        expect(vm.rules).toEqual(monacoRules);
        expect(vm.model.options).toMatchObject(monacoRules);
        expect(vm.getFileData).not.toHaveBeenCalled();
        expect(vm.getRawFileData).not.toHaveBeenCalled();
      },
    );

    it('fetches content from remote for .editorconfig files not available locally', async () => {
      const activeFile = createActiveFile({
        path: 'foo/bar/baz/test/my_spec.js',
        key: 'foo/bar/baz/test/my_spec.js',
        name: 'myfile.txt',
        content: 'hello world',
      });

      const expectations = [
        'foo/bar/baz/.editorconfig',
        'foo/bar/.editorconfig',
        'foo/.editorconfig',
        '.editorconfig',
      ];

      await createComponent({
        state: {
          entries: (() => {
            const res = {
              [activeFile.path]: activeFile,
            };
            exampleConfigs.forEach(({ path: configPath }) => {
              const f = { ...file(), path: configPath };
              delete f.content;
              delete f.raw;
              res[configPath] = f;
            });
            return res;
          })(),
        },
        activeFile,
      });

      expect(service.getFileData.mock.calls.map(([args]) => args)).toEqual(
        expectations.map((expectation) => expect.stringContaining(expectation)),
      );
      expect(service.getRawFileData.mock.calls.map(([args]) => args)).toEqual(
        expectations.map((expectation) => expect.objectContaining({ path: expectation })),
      );
    });
  });
});
