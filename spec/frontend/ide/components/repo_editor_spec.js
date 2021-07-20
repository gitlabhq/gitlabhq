import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { editor as monacoEditor, Range } from 'monaco-editor';
import Vue from 'vue';
import Vuex from 'vuex';
import '~/behaviors/markdown/render_gfm';
import waitForPromises from 'helpers/wait_for_promises';
import waitUsingRealTimer from 'helpers/wait_using_real_timer';
import { exampleConfigs, exampleFiles } from 'jest/ide/lib/editorconfig/mock_data';
import { EDITOR_CODE_INSTANCE_FN, EDITOR_DIFF_INSTANCE_FN } from '~/editor/constants';
import { EditorWebIdeExtension } from '~/editor/extensions/source_editor_webide_ext';
import SourceEditor from '~/editor/source_editor';
import RepoEditor from '~/ide/components/repo_editor.vue';
import {
  leftSidebarViews,
  FILE_VIEW_MODE_EDITOR,
  FILE_VIEW_MODE_PREVIEW,
  viewerTypes,
} from '~/ide/constants';
import ModelManager from '~/ide/lib/common/model_manager';
import service from '~/ide/services';
import { createStoreOptions } from '~/ide/stores';
import axios from '~/lib/utils/axios_utils';
import ContentViewer from '~/vue_shared/components/content_viewer/content_viewer.vue';
import { file } from '../helpers';

const defaultFileProps = {
  ...file('file.txt'),
  content: 'hello world',
  active: true,
  tempFile: true,
};
const createActiveFile = (props) => {
  return {
    ...defaultFileProps,
    ...props,
  };
};

const dummyFile = {
  markdown: (() =>
    createActiveFile({
      projectId: 'namespace/project',
      path: 'sample.md',
      name: 'sample.md',
    }))(),
  binary: (() =>
    createActiveFile({
      name: 'file.dat',
      content: '🐱', // non-ascii binary content,
    }))(),
  empty: (() =>
    createActiveFile({
      tempFile: false,
      content: '',
      raw: '',
    }))(),
};

const prepareStore = (state, activeFile) => {
  const localState = {
    openFiles: [activeFile],
    projects: {
      'gitlab-org/gitlab': {
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
    currentProjectId: 'gitlab-org/gitlab',
    currentBranchId: 'main',
    entries: {
      [activeFile.path]: activeFile,
    },
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

  const waitForEditorSetup = () =>
    new Promise((resolve) => {
      vm.$once('editorSetup', resolve);
    });

  const createComponent = async ({ state = {}, activeFile = defaultFileProps } = {}) => {
    const store = prepareStore(state, activeFile);
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
    jest.spyOn(vm, 'getFileData').mockResolvedValue();
    jest.spyOn(vm, 'getRawFileData').mockResolvedValue();
  };

  const findEditor = () => wrapper.find('[data-testid="editor-container"]');
  const findTabs = () => wrapper.findAll('.ide-mode-tabs .nav-links li');
  const findPreviewTab = () => wrapper.find('[data-testid="preview-tab"]');

  beforeEach(() => {
    createInstanceSpy = jest.spyOn(SourceEditor.prototype, EDITOR_CODE_INSTANCE_FN);
    createDiffInstanceSpy = jest.spyOn(SourceEditor.prototype, EDITOR_DIFF_INSTANCE_FN);
    createModelSpy = jest.spyOn(monacoEditor, 'createModel');
    jest.spyOn(service, 'getFileData').mockResolvedValue();
    jest.spyOn(service, 'getRawFileData').mockResolvedValue();
  });

  afterEach(() => {
    jest.clearAllMocks();
    // create a new model each time, otherwise tests conflict with each other
    // because of same model being used in multiple tests
    // eslint-disable-next-line no-undef
    monaco.editor.getModels().forEach((model) => model.dispose());
    wrapper.destroy();
    wrapper = null;
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

    it('renders only an edit tab', async () => {
      await createComponent();
      const tabs = findTabs();

      expect(tabs).toHaveLength(1);
      expect(tabs.at(0).text()).toBe('Edit');
    });
  });

  describe('when file is markdown', () => {
    let mock;
    let activeFile;

    beforeEach(() => {
      activeFile = dummyFile.markdown;

      mock = new MockAdapter(axios);

      mock.onPost(/(.*)\/preview_markdown/).reply(200, {
        body: `<p>${defaultFileProps.content}</p>`,
      });
    });

    afterEach(() => {
      mock.restore();
    });

    it('renders an Edit and a Preview Tab', async () => {
      await createComponent({ activeFile });
      const tabs = findTabs();

      expect(tabs).toHaveLength(2);
      expect(tabs.at(0).text()).toBe('Edit');
      expect(tabs.at(1).text()).toBe('Preview Markdown');
    });

    it('renders markdown for tempFile', async () => {
      // by default files created in the spec are temp: no need for explicitly sending the param
      await createComponent({ activeFile });

      findPreviewTab().trigger('click');
      await waitForPromises();
      expect(wrapper.find(ContentViewer).html()).toContain(defaultFileProps.content);
    });

    it('shows no tabs when not in Edit mode', async () => {
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
      const extensionSpy = jest.spyOn(SourceEditor, 'instanceApplyExtension');
      await createComponent();
      expect(extensionSpy).toHaveBeenCalled();
      Reflect.ownKeys(EditorWebIdeExtension.prototype)
        .filter((fn) => fn !== 'constructor')
        .forEach((fn) => {
          expect(vm.editor[fn]).toBe(EditorWebIdeExtension.prototype[fn]);
        });
    });
  });

  describe('setupEditor', () => {
    beforeEach(async () => {
      await createComponent();
    });

    it('creates new model on load', () => {
      // We always create two models per file to be able to build a diff of changes
      expect(createModelSpy).toHaveBeenCalledTimes(2);
      // The model with the most recent changes is the last one
      const [content] = createModelSpy.mock.calls[1];
      expect(content).toBe(defaultFileProps.content);
    });

    it('does not create a new model on subsequent calls to setupEditor and re-uses the already-existing model', () => {
      const existingModel = vm.model;
      createModelSpy.mockClear();

      vm.setupEditor();

      expect(createModelSpy).not.toHaveBeenCalled();
      expect(vm.model).toBe(existingModel);
    });

    it('adds callback methods', () => {
      jest.spyOn(vm.editor, 'onPositionChange');
      jest.spyOn(vm.model, 'onChange');
      jest.spyOn(vm.model, 'updateOptions');

      vm.setupEditor();

      expect(vm.editor.onPositionChange).toHaveBeenCalledTimes(1);
      expect(vm.model.onChange).toHaveBeenCalledTimes(1);
      expect(vm.model.updateOptions).toHaveBeenCalledWith(vm.rules);
    });

    it('updates state with the value of the model', () => {
      const newContent = 'As Gregor Samsa\n awoke one morning\n';
      vm.model.setValue(newContent);

      vm.setupEditor();

      expect(vm.file.content).toBe(newContent);
    });

    it('sets head model as staged file', () => {
      vm.modelManager.dispose();
      const addModelSpy = jest.spyOn(ModelManager.prototype, 'addModel');

      vm.$store.state.stagedFiles.push({ ...vm.file, key: 'staged' });
      vm.file.staged = true;
      vm.file.key = `unstaged-${vm.file.key}`;

      vm.setupEditor();

      expect(addModelSpy).toHaveBeenCalledWith(vm.file, vm.$store.state.stagedFiles[0]);
    });
  });

  describe('editor updateDimensions', () => {
    let updateDimensionsSpy;
    let updateDiffViewSpy;
    beforeEach(async () => {
      await createComponent();
      updateDimensionsSpy = jest.spyOn(vm.editor, 'updateDimensions');
      updateDiffViewSpy = jest.spyOn(vm.editor, 'updateDiffView').mockImplementation();
    });

    it('calls updateDimensions only when panelResizing is false', async () => {
      expect(updateDimensionsSpy).not.toHaveBeenCalled();
      expect(updateDiffViewSpy).not.toHaveBeenCalled();
      expect(vm.$store.state.panelResizing).toBe(false); // default value

      vm.$store.state.panelResizing = true;
      await vm.$nextTick();

      expect(updateDimensionsSpy).not.toHaveBeenCalled();
      expect(updateDiffViewSpy).not.toHaveBeenCalled();

      vm.$store.state.panelResizing = false;
      await vm.$nextTick();

      expect(updateDimensionsSpy).toHaveBeenCalledTimes(1);
      expect(updateDiffViewSpy).toHaveBeenCalledTimes(1);

      vm.$store.state.panelResizing = true;
      await vm.$nextTick();

      expect(updateDimensionsSpy).toHaveBeenCalledTimes(1);
      expect(updateDiffViewSpy).toHaveBeenCalledTimes(1);
    });

    it('calls updateDimensions when rightPane is toggled', async () => {
      expect(updateDimensionsSpy).not.toHaveBeenCalled();
      expect(updateDiffViewSpy).not.toHaveBeenCalled();
      expect(vm.$store.state.rightPane.isOpen).toBe(false); // default value

      vm.$store.state.rightPane.isOpen = true;
      await vm.$nextTick();

      expect(updateDimensionsSpy).toHaveBeenCalledTimes(1);
      expect(updateDiffViewSpy).toHaveBeenCalledTimes(1);

      vm.$store.state.rightPane.isOpen = false;
      await vm.$nextTick();

      expect(updateDimensionsSpy).toHaveBeenCalledTimes(2);
      expect(updateDiffViewSpy).toHaveBeenCalledTimes(2);
    });
  });

  describe('editor tabs', () => {
    beforeEach(async () => {
      await createComponent();
    });

    it.each`
      mode        | isVisible
      ${'edit'}   | ${true}
      ${'review'} | ${false}
      ${'commit'} | ${false}
    `('tabs in $mode are $isVisible', async ({ mode, isVisible } = {}) => {
      vm.$store.state.currentActivityView = leftSidebarViews[mode].name;

      await vm.$nextTick();
      expect(wrapper.find('.nav-links').exists()).toBe(isVisible);
    });
  });

  describe('files in preview mode', () => {
    let updateDimensionsSpy;
    const changeViewMode = (viewMode) =>
      vm.$store.dispatch('editor/updateFileEditor', {
        path: vm.file.path,
        data: { viewMode },
      });

    beforeEach(async () => {
      await createComponent({
        activeFile: dummyFile.markdown,
      });

      updateDimensionsSpy = jest.spyOn(vm.editor, 'updateDimensions');

      changeViewMode(FILE_VIEW_MODE_PREVIEW);
      await vm.$nextTick();
    });

    it('do not show the editor', () => {
      expect(vm.showEditor).toBe(false);
      expect(findEditor().isVisible()).toBe(false);
    });

    it('updates dimensions when switching view back to edit', async () => {
      expect(updateDimensionsSpy).not.toHaveBeenCalled();

      changeViewMode(FILE_VIEW_MODE_EDITOR);
      await vm.$nextTick();

      expect(updateDimensionsSpy).toHaveBeenCalled();
    });
  });

  describe('initEditor', () => {
    const hideEditorAndRunFn = async () => {
      jest.clearAllMocks();
      jest.spyOn(vm, 'shouldHideEditor', 'get').mockReturnValue(true);

      vm.initEditor();
      await vm.$nextTick();
    };

    it('does not fetch file information for temp entries', async () => {
      await createComponent({
        activeFile: createActiveFile(),
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
        activeFile: createActiveFile(),
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
      await vm.$nextTick();

      wrapper.setProps({
        file: file('testing'),
      });
      vm.file.content = 'foo'; // need to prevent full cycle of initEditor
      await vm.$nextTick();

      expect(vm.removePendingTab).toHaveBeenCalledWith(origFile);
    });

    it('does not call initEditor if the file did not change', async () => {
      Vue.set(vm, 'file', vm.file);
      await vm.$nextTick();

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
      await vm.$nextTick();
      await vm.$nextTick();

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
      Vue.set(vm.$store.state.entries, f.path, f);

      jest.spyOn(service, 'getRawFileData').mockImplementation(async () => {
        expect(vm.file.loading).toBe(true);

        // switching from edit to diff mode usually triggers editor initialization
        vm.$store.state.viewer = viewerTypes.diff;

        // we delay returning the file to make sure editor doesn't initialize before we fetch file content
        await waitUsingRealTimer(30);
        return 'rawFileData123\n';
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
      Vue.set(vm.$store.state.entries, fileA.path, fileA);
      Vue.set(vm.$store.state.entries, fileB.path, fileB);

      jest
        .spyOn(service, 'getRawFileData')
        .mockImplementation(async () => {
          // opening fileB while the content of fileA is still being fetched
          wrapper.setProps({
            file: fileB,
          });
          return aContent;
        })
        .mockImplementationOnce(async () => {
          // we delay returning fileB content to make sure the editor doesn't initialize prematurely
          await waitUsingRealTimer(30);
          return bContent;
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

      vm.setupEditor();

      await waitForPromises();
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
