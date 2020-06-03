import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import '~/behaviors/markdown/render_gfm';
import { Range } from 'monaco-editor';
import axios from '~/lib/utils/axios_utils';
import { createStore } from '~/ide/stores';
import repoEditor from '~/ide/components/repo_editor.vue';
import Editor from '~/ide/lib/editor';
import { leftSidebarViews, FILE_VIEW_MODE_EDITOR, FILE_VIEW_MODE_PREVIEW } from '~/ide/constants';
import { createComponentWithStore } from '../../helpers/vue_mount_component_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { file } from '../helpers';

describe('RepoEditor', () => {
  let vm;
  let store;

  beforeEach(() => {
    const f = {
      ...file(),
      viewMode: FILE_VIEW_MODE_EDITOR,
    };
    const RepoEditor = Vue.extend(repoEditor);

    store = createStore();
    vm = createComponentWithStore(RepoEditor, store, {
      file: f,
    });

    f.active = true;
    f.tempFile = true;

    vm.$store.state.openFiles.push(f);
    vm.$store.state.projects = {
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
    vm.$store.state.currentProjectId = 'gitlab-org/gitlab';
    vm.$store.state.currentBranchId = 'master';

    Vue.set(vm.$store.state.entries, f.path, f);

    jest.spyOn(vm, 'getFileData').mockResolvedValue();
    jest.spyOn(vm, 'getRawFileData').mockResolvedValue();

    vm.$mount();

    return vm.$nextTick();
  });

  afterEach(() => {
    vm.$destroy();

    Editor.editorInstance.dispose();
  });

  const findEditor = () => vm.$el.querySelector('.multi-file-editor-holder');

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
    beforeEach(done => {
      vm.file.previewMode = {
        id: 'markdown',
        previewTitle: 'Preview Markdown',
      };

      vm.$nextTick(done);
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
  });

  describe('when file is markdown and viewer mode is review', () => {
    let mock;

    beforeEach(done => {
      mock = new MockAdapter(axios);

      vm.file.projectId = 'namespace/project';
      vm.file.previewMode = {
        id: 'markdown',
        previewTitle: 'Preview Markdown',
      };
      vm.file.content = 'testing 123';
      vm.$store.state.viewer = 'diff';

      mock.onPost(/(.*)\/preview_markdown/).reply(200, {
        body: '<p>testing 123</p>',
      });

      vm.$nextTick(done);
    });

    afterEach(() => {
      mock.restore();
    });

    it('renders an Edit and a Preview Tab', done => {
      Vue.nextTick(() => {
        const tabs = vm.$el.querySelectorAll('.ide-mode-tabs .nav-links li');

        expect(tabs.length).toBe(2);
        expect(tabs[0].textContent.trim()).toBe('Review');
        expect(tabs[1].textContent.trim()).toBe('Preview Markdown');

        done();
      });
    });

    it('renders markdown for tempFile', done => {
      vm.file.tempFile = true;
      vm.file.path = `${vm.file.path}.md`;
      vm.$store.state.entries[vm.file.path] = vm.file;

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
  });

  describe('when open file is binary and not raw', () => {
    beforeEach(done => {
      vm.file.binary = true;

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
      vm.model.setValue('testing 1234');

      vm.setupEditor();

      expect(vm.file.content).toBe('testing 1234');
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
      vm.file.viewMode = FILE_VIEW_MODE_PREVIEW;
      vm.$nextTick(done);
    });

    it('should hide editor', () => {
      expect(vm.showEditor).toBe(false);
      expect(findEditor()).toHaveCss({ display: 'none' });
    });

    describe('when file view mode changes to editor', () => {
      it('should update dimensions', () => {
        vm.file.viewMode = FILE_VIEW_MODE_EDITOR;

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
      });
    });

    it('adds an image entry to the same folder for a pasted image in a markdown file', () => {
      pasteImage();

      return waitForPromises().then(() => {
        expect(vm.$store.state.entries['foo/foo.png']).toMatchObject({
          path: 'foo/foo.png',
          type: 'blob',
          content: 'Zm9v',
          base64: true,
          binary: true,
          rawPath: 'data:image/png;base64,Zm9v',
        });
      });
    });

    it("adds a markdown image tag to the file's contents", () => {
      pasteImage();

      // Pasting an image does a lot of things like using the FileReader API,
      // so, waitForPromises isn't very reliable (and causes a flaky spec)
      // Read more about state.watch: https://vuex.vuejs.org/api/#watch
      return watchState(s => s.entries['foo/bar.md'].content).then(() => {
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
