import Vuex from 'vuex';
import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import '~/behaviors/markdown/render_gfm';
import { Range } from 'monaco-editor';
import waitForPromises from 'helpers/wait_for_promises';
import waitUsingRealTimer from 'helpers/wait_using_real_timer';
import axios from '~/lib/utils/axios_utils';
import service from '~/ide/services';
import { createStoreOptions } from '~/ide/stores';
import RepoEditor from '~/ide/components/repo_editor.vue';
import Editor from '~/ide/lib/editor';
import {
  leftSidebarViews,
  FILE_VIEW_MODE_EDITOR,
  FILE_VIEW_MODE_PREVIEW,
  viewerTypes,
} from '~/ide/constants';
import { createComponentWithStore } from '../../helpers/vue_mount_component_helper';
import { file } from '../helpers';
import { exampleConfigs, exampleFiles } from '../lib/editorconfig/mock_data';

describe('RepoEditor', () => {
  let vm;
  let store;

  const waitForEditorSetup = () =>
    new Promise(resolve => {
      vm.$once('editorSetup', resolve);
    });

  const createComponent = () => {
    if (vm) {
      throw new Error('vm already exists');
    }
    vm = createComponentWithStore(Vue.extend(RepoEditor), store, {
      file: store.state.openFiles[0],
    });

    jest.spyOn(vm, 'getFileData').mockResolvedValue();
    jest.spyOn(vm, 'getRawFileData').mockResolvedValue();

    vm.$mount();
  };

  const createOpenFile = path => {
    const origFile = store.state.openFiles[0];
    const newFile = { ...origFile, path, key: path, name: 'myfile.txt', content: 'hello world' };

    store.state.entries[path] = newFile;

    store.state.openFiles = [newFile];
  };

  beforeEach(() => {
    const f = {
      ...file('file.txt'),
      content: 'hello world',
    };

    const storeOptions = createStoreOptions();
    store = new Vuex.Store(storeOptions);

    f.active = true;
    f.tempFile = true;

    store.state.openFiles.push(f);
    store.state.projects = {
      'gitlab-org/gitlab': {
        branches: {
          master: {
            name: 'master',
            commit: {
              id: 'abcdefgh',
            },
          },
        },
      },
    };
    store.state.currentProjectId = 'gitlab-org/gitlab';
    store.state.currentBranchId = 'master';

    Vue.set(store.state.entries, f.path, f);
  });

  afterEach(() => {
    vm.$destroy();
    vm = null;

    Editor.editorInstance.dispose();
  });

  const findEditor = () => vm.$el.querySelector('.multi-file-editor-holder');
  const changeViewMode = viewMode =>
    store.dispatch('editor/updateFileEditor', { path: vm.file.path, data: { viewMode } });

  describe('default', () => {
    beforeEach(() => {
      createComponent();

      return waitForEditorSetup();
    });

    it('sets renderWhitespace to `all`', () => {
      vm.$store.state.renderWhitespaceInCode = true;

      expect(vm.editorOptions.renderWhitespace).toEqual('all');
    });

    it('sets renderWhitespace to `none`', () => {
      vm.$store.state.renderWhitespaceInCode = false;

      expect(vm.editorOptions.renderWhitespace).toEqual('none');
    });

    it('renders an ide container', () => {
      expect(vm.shouldHideEditor).toBeFalsy();
      expect(vm.showEditor).toBe(true);
      expect(findEditor()).not.toHaveCss({ display: 'none' });
    });

    it('renders only an edit tab', done => {
      Vue.nextTick(() => {
        const tabs = vm.$el.querySelectorAll('.ide-mode-tabs .nav-links li');

        expect(tabs.length).toBe(1);
        expect(tabs[0].textContent.trim()).toBe('Edit');

        done();
      });
    });

    describe('when file is markdown', () => {
      let mock;

      beforeEach(() => {
        mock = new MockAdapter(axios);

        mock.onPost(/(.*)\/preview_markdown/).reply(200, {
          body: '<p>testing 123</p>',
        });

        Vue.set(vm, 'file', {
          ...vm.file,
          projectId: 'namespace/project',
          path: 'sample.md',
          name: 'sample.md',
          content: 'testing 123',
        });

        vm.$store.state.entries[vm.file.path] = vm.file;

        return vm.$nextTick();
      });

      afterEach(() => {
        mock.restore();
      });

      it('renders an Edit and a Preview Tab', done => {
        Vue.nextTick(() => {
          const tabs = vm.$el.querySelectorAll('.ide-mode-tabs .nav-links li');

          expect(tabs.length).toBe(2);
          expect(tabs[0].textContent.trim()).toBe('Edit');
          expect(tabs[1].textContent.trim()).toBe('Preview Markdown');

          done();
        });
      });

      it('renders markdown for tempFile', done => {
        vm.file.tempFile = true;

        vm.$nextTick()
          .then(() => {
            vm.$el.querySelectorAll('.ide-mode-tabs .nav-links a')[1].click();
          })
          .then(waitForPromises)
          .then(() => {
            expect(vm.$el.querySelector('.preview-container').innerHTML).toContain(
              '<p>testing 123</p>',
            );
          })
          .then(done)
          .catch(done.fail);
      });

      describe('when not in edit mode', () => {
        beforeEach(async () => {
          await vm.$nextTick();

          vm.$store.state.currentActivityView = leftSidebarViews.review.name;

          return vm.$nextTick();
        });

        it('shows no tabs', () => {
          expect(vm.$el.querySelectorAll('.ide-mode-tabs .nav-links a')).toHaveLength(0);
        });
      });
    });

    describe('when open file is binary and not raw', () => {
      beforeEach(done => {
        vm.file.name = 'file.dat';
        vm.file.content = '🐱'; // non-ascii binary content

        vm.$nextTick(done);
      });

      it('does not render the IDE', () => {
        expect(vm.shouldHideEditor).toBeTruthy();
      });
    });

    describe('createEditorInstance', () => {
      it('calls createInstance when viewer is editor', done => {
        jest.spyOn(vm.editor, 'createInstance').mockImplementation();

        vm.createEditorInstance();

        vm.$nextTick(() => {
          expect(vm.editor.createInstance).toHaveBeenCalled();

          done();
        });
      });

      it('calls createDiffInstance when viewer is diff', done => {
        vm.$store.state.viewer = 'diff';

        jest.spyOn(vm.editor, 'createDiffInstance').mockImplementation();

        vm.createEditorInstance();

        vm.$nextTick(() => {
          expect(vm.editor.createDiffInstance).toHaveBeenCalled();

          done();
        });
      });

      it('calls createDiffInstance when viewer is a merge request diff', done => {
        vm.$store.state.viewer = 'mrdiff';

        jest.spyOn(vm.editor, 'createDiffInstance').mockImplementation();

        vm.createEditorInstance();

        vm.$nextTick(() => {
          expect(vm.editor.createDiffInstance).toHaveBeenCalled();

          done();
        });
      });
    });

    describe('setupEditor', () => {
      it('creates new model', () => {
        jest.spyOn(vm.editor, 'createModel');

        Editor.editorInstance.modelManager.dispose();

        vm.setupEditor();

        expect(vm.editor.createModel).toHaveBeenCalledWith(vm.file, null);
        expect(vm.model).not.toBeNull();
      });

      it('attaches model to editor', () => {
        jest.spyOn(vm.editor, 'attachModel');

        Editor.editorInstance.modelManager.dispose();

        vm.setupEditor();

        expect(vm.editor.attachModel).toHaveBeenCalledWith(vm.model);
      });

      it('attaches model to merge request editor', () => {
        vm.$store.state.viewer = 'mrdiff';
        vm.file.mrChange = true;
        jest.spyOn(vm.editor, 'attachMergeRequestModel').mockImplementation();

        Editor.editorInstance.modelManager.dispose();

        vm.setupEditor();

        expect(vm.editor.attachMergeRequestModel).toHaveBeenCalledWith(vm.model);
      });

      it('does not attach model to merge request editor when not a MR change', () => {
        vm.$store.state.viewer = 'mrdiff';
        vm.file.mrChange = false;
        jest.spyOn(vm.editor, 'attachMergeRequestModel').mockImplementation();

        Editor.editorInstance.modelManager.dispose();

        vm.setupEditor();

        expect(vm.editor.attachMergeRequestModel).not.toHaveBeenCalledWith(vm.model);
      });

      it('adds callback methods', () => {
        jest.spyOn(vm.editor, 'onPositionChange');

        Editor.editorInstance.modelManager.dispose();

        vm.setupEditor();

        expect(vm.editor.onPositionChange).toHaveBeenCalled();
        expect(vm.model.events.size).toBe(2);
      });

      it('updates state with the value of the model', () => {
        vm.model.setValue('testing 1234\n');

        vm.setupEditor();

        expect(vm.file.content).toBe('testing 1234\n');
      });

      it('sets head model as staged file', () => {
        jest.spyOn(vm.editor, 'createModel');

        Editor.editorInstance.modelManager.dispose();

        vm.$store.state.stagedFiles.push({ ...vm.file, key: 'staged' });
        vm.file.staged = true;
        vm.file.key = `unstaged-${vm.file.key}`;

        vm.setupEditor();

        expect(vm.editor.createModel).toHaveBeenCalledWith(vm.file, vm.$store.state.stagedFiles[0]);
      });
    });

    describe('editor updateDimensions', () => {
      beforeEach(() => {
        jest.spyOn(vm.editor, 'updateDimensions');
        jest.spyOn(vm.editor, 'updateDiffView').mockImplementation();
      });

      it('calls updateDimensions when panelResizing is false', done => {
        vm.$store.state.panelResizing = true;

        vm.$nextTick()
          .then(() => {
            vm.$store.state.panelResizing = false;
          })
          .then(vm.$nextTick)
          .then(() => {
            expect(vm.editor.updateDimensions).toHaveBeenCalled();
            expect(vm.editor.updateDiffView).toHaveBeenCalled();
          })
          .then(done)
          .catch(done.fail);
      });

      it('does not call updateDimensions when panelResizing is true', done => {
        vm.$store.state.panelResizing = true;

        vm.$nextTick(() => {
          expect(vm.editor.updateDimensions).not.toHaveBeenCalled();
          expect(vm.editor.updateDiffView).not.toHaveBeenCalled();

          done();
        });
      });

      it('calls updateDimensions when rightPane is opened', done => {
        vm.$store.state.rightPane.isOpen = true;

        vm.$nextTick(() => {
          expect(vm.editor.updateDimensions).toHaveBeenCalled();
          expect(vm.editor.updateDiffView).toHaveBeenCalled();

          done();
        });
      });
    });

    describe('show tabs', () => {
      it('shows tabs in edit mode', () => {
        expect(vm.$el.querySelector('.nav-links')).not.toBe(null);
      });

      it('hides tabs in review mode', done => {
        vm.$store.state.currentActivityView = leftSidebarViews.review.name;

        vm.$nextTick(() => {
          expect(vm.$el.querySelector('.nav-links')).toBe(null);

          done();
        });
      });

      it('hides tabs in commit mode', done => {
        vm.$store.state.currentActivityView = leftSidebarViews.commit.name;

        vm.$nextTick(() => {
          expect(vm.$el.querySelector('.nav-links')).toBe(null);

          done();
        });
      });
    });

    describe('when files view mode is preview', () => {
      beforeEach(done => {
        jest.spyOn(vm.editor, 'updateDimensions').mockImplementation();
        changeViewMode(FILE_VIEW_MODE_PREVIEW);
        vm.file.name = 'myfile.md';
        vm.file.content = 'hello world';

        vm.$nextTick(done);
      });

      it('should hide editor', () => {
        expect(vm.showEditor).toBe(false);
        expect(findEditor()).toHaveCss({ display: 'none' });
      });

      describe('when file view mode changes to editor', () => {
        it('should update dimensions', () => {
          changeViewMode(FILE_VIEW_MODE_EDITOR);

          return vm.$nextTick().then(() => {
            expect(vm.editor.updateDimensions).toHaveBeenCalled();
          });
        });
      });
    });

    describe('initEditor', () => {
      beforeEach(() => {
        vm.file.tempFile = false;
        jest.spyOn(vm.editor, 'createInstance').mockImplementation();
        jest.spyOn(vm, 'shouldHideEditor', 'get').mockReturnValue(true);
      });

      it('does not fetch file information for temp entries', done => {
        vm.file.tempFile = true;

        vm.initEditor();
        vm.$nextTick()
          .then(() => {
            expect(vm.getFileData).not.toHaveBeenCalled();
          })
          .then(done)
          .catch(done.fail);
      });

      it('is being initialised for files without content even if shouldHideEditor is `true`', done => {
        vm.file.content = '';
        vm.file.raw = '';

        vm.initEditor();

        vm.$nextTick()
          .then(() => {
            expect(vm.getFileData).toHaveBeenCalled();
            expect(vm.getRawFileData).toHaveBeenCalled();
          })
          .then(done)
          .catch(done.fail);
      });

      it('does not initialize editor for files already with content', done => {
        vm.file.content = 'foo';

        vm.initEditor();
        vm.$nextTick()
          .then(() => {
            expect(vm.getFileData).not.toHaveBeenCalled();
            expect(vm.getRawFileData).not.toHaveBeenCalled();
            expect(vm.editor.createInstance).not.toHaveBeenCalled();
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('updates on file changes', () => {
      beforeEach(() => {
        jest.spyOn(vm, 'initEditor').mockImplementation();
      });

      it('calls removePendingTab when old file is pending', done => {
        jest.spyOn(vm, 'shouldHideEditor', 'get').mockReturnValue(true);
        jest.spyOn(vm, 'removePendingTab').mockImplementation();

        vm.file.pending = true;

        vm.$nextTick()
          .then(() => {
            vm.file = file('testing');
            vm.file.content = 'foo'; // need to prevent full cycle of initEditor

            return vm.$nextTick();
          })
          .then(() => {
            expect(vm.removePendingTab).toHaveBeenCalled();
          })
          .then(done)
          .catch(done.fail);
      });

      it('does not call initEditor if the file did not change', done => {
        Vue.set(vm, 'file', vm.file);

        vm.$nextTick()
          .then(() => {
            expect(vm.initEditor).not.toHaveBeenCalled();
          })
          .then(done)
          .catch(done.fail);
      });

      it('calls initEditor when file key is changed', done => {
        expect(vm.initEditor).not.toHaveBeenCalled();

        Vue.set(vm, 'file', {
          ...vm.file,
          key: 'new',
        });

        vm.$nextTick()
          .then(() => {
            expect(vm.initEditor).toHaveBeenCalled();
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('populates editor with the fetched content', () => {
      beforeEach(() => {
        vm.getRawFileData.mockRestore();
      });

      const createRemoteFile = name => ({
        ...file(name),
        tmpFile: false,
      });

      it('after switching viewer from edit to diff', async () => {
        jest.spyOn(service, 'getRawFileData').mockImplementation(async () => {
          expect(vm.file.loading).toBe(true);

          // switching from edit to diff mode usually triggers editor initialization
          store.state.viewer = viewerTypes.diff;

          // we delay returning the file to make sure editor doesn't initialize before we fetch file content
          await waitUsingRealTimer(30);
          return 'rawFileData123\n';
        });

        const f = createRemoteFile('newFile');
        Vue.set(store.state.entries, f.path, f);

        vm.file = f;

        await waitForEditorSetup();
        expect(vm.model.getModel().getValue()).toBe('rawFileData123\n');
      });

      it('after opening multiple files at the same time', async () => {
        const fileA = createRemoteFile('fileA');
        const fileB = createRemoteFile('fileB');
        Vue.set(store.state.entries, fileA.path, fileA);
        Vue.set(store.state.entries, fileB.path, fileB);

        jest
          .spyOn(service, 'getRawFileData')
          .mockImplementationOnce(async () => {
            // opening fileB while the content of fileA is still being fetched
            vm.file = fileB;
            return 'fileA-rawContent\n';
          })
          .mockImplementationOnce(async () => {
            // we delay returning fileB content to make sure the editor doesn't initialize prematurely
            await waitUsingRealTimer(30);
            return 'fileB-rawContent\n';
          });

        vm.file = fileA;

        await waitForEditorSetup();
        expect(vm.model.getModel().getValue()).toBe('fileB-rawContent\n');
      });
    });

    describe('onPaste', () => {
      const setFileName = name => {
        Vue.set(vm, 'file', {
          ...vm.file,
          content: 'hello world\n',
          name,
          path: `foo/${name}`,
          key: 'new',
        });

        vm.$store.state.entries[vm.file.path] = vm.file;
      };

      const pasteImage = () => {
        window.dispatchEvent(
          Object.assign(new Event('paste'), {
            clipboardData: {
              files: [new File(['foo'], 'foo.png', { type: 'image/png' })],
            },
          }),
        );
      };

      const watchState = watched =>
        new Promise(resolve => {
          const unwatch = vm.$store.watch(watched, () => {
            unwatch();
            resolve();
          });
        });

      // Pasting an image does a lot of things like using the FileReader API,
      // so, waitForPromises isn't very reliable (and causes a flaky spec)
      // Read more about state.watch: https://vuex.vuejs.org/api/#watch
      const waitForFileContentChange = () => watchState(s => s.entries['foo/bar.md'].content);

      beforeEach(() => {
        setFileName('bar.md');

        vm.$store.state.trees['gitlab-org/gitlab'] = { tree: [] };
        vm.$store.state.currentProjectId = 'gitlab-org';
        vm.$store.state.currentBranchId = 'gitlab';

        // create a new model each time, otherwise tests conflict with each other
        // because of same model being used in multiple tests
        Editor.editorInstance.modelManager.dispose();
        vm.setupEditor();

        return waitForPromises().then(() => {
          // set cursor to line 2, column 1
          vm.editor.instance.setSelection(new Range(2, 1, 2, 1));
          vm.editor.instance.focus();

          jest.spyOn(vm.editor.instance, 'hasTextFocus').mockReturnValue(true);
        });
      });

      it('adds an image entry to the same folder for a pasted image in a markdown file', () => {
        pasteImage();

        return waitForFileContentChange().then(() => {
          expect(vm.$store.state.entries['foo/foo.png']).toMatchObject({
            path: 'foo/foo.png',
            type: 'blob',
            content: 'Zm9v',
            rawPath: 'data:image/png;base64,Zm9v',
          });
        });
      });

      it("adds a markdown image tag to the file's contents", () => {
        pasteImage();

        return waitForFileContentChange().then(() => {
          expect(vm.file.content).toBe('hello world\n![foo.png](./foo.png)');
        });
      });

      it("does not add file to state or set markdown image syntax if the file isn't markdown", () => {
        setFileName('myfile.txt');
        pasteImage();

        return waitForPromises().then(() => {
          expect(vm.$store.state.entries['foo/foo.png']).toBeUndefined();
          expect(vm.file.content).toBe('hello world\n');
        });
      });
    });
  });

  describe('fetchEditorconfigRules', () => {
    beforeEach(() => {
      exampleConfigs.forEach(({ path, content }) => {
        store.state.entries[path] = { ...file(), path, content };
      });
    });

    it.each(exampleFiles)(
      'does not fetch content from remote for .editorconfig files present locally (case %#)',
      ({ path, monacoRules }) => {
        createOpenFile(path);
        createComponent();

        return waitForEditorSetup().then(() => {
          expect(vm.rules).toEqual(monacoRules);
          expect(vm.model.options).toMatchObject(monacoRules);
          expect(vm.getFileData).not.toHaveBeenCalled();
          expect(vm.getRawFileData).not.toHaveBeenCalled();
        });
      },
    );

    it('fetches content from remote for .editorconfig files not available locally', () => {
      exampleConfigs.forEach(({ path }) => {
        delete store.state.entries[path].content;
        delete store.state.entries[path].raw;
      });

      // Include a "test" directory which does not exist in store. This one should be skipped.
      createOpenFile('foo/bar/baz/test/my_spec.js');
      createComponent();

      return waitForEditorSetup().then(() => {
        expect(vm.getFileData.mock.calls.map(([args]) => args)).toEqual([
          { makeFileActive: false, path: 'foo/bar/baz/.editorconfig' },
          { makeFileActive: false, path: 'foo/bar/.editorconfig' },
          { makeFileActive: false, path: 'foo/.editorconfig' },
          { makeFileActive: false, path: '.editorconfig' },
        ]);
        expect(vm.getRawFileData.mock.calls.map(([args]) => args)).toEqual([
          { path: 'foo/bar/baz/.editorconfig' },
          { path: 'foo/bar/.editorconfig' },
          { path: 'foo/.editorconfig' },
          { path: '.editorconfig' },
        ]);
      });
    });
  });
});
