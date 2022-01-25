import Vue, { nextTick } from 'vue';
import { createComponentWithStore } from 'helpers/vue_mount_component_helper';
import FileRowExtra from '~/ide/components/file_row_extra.vue';
import { createStore } from '~/ide/stores';
import { file } from '../helpers';

describe('IDE extra file row component', () => {
  let Component;
  let vm;
  let unstagedFilesCount = 0;
  let stagedFilesCount = 0;
  let changesCount = 0;

  beforeAll(() => {
    Component = Vue.extend(FileRowExtra);
  });

  beforeEach(() => {
    vm = createComponentWithStore(Component, createStore(), {
      file: {
        ...file('test'),
      },
      dropdownOpen: false,
    });

    jest.spyOn(vm, 'getUnstagedFilesCountForPath', 'get').mockReturnValue(() => unstagedFilesCount);
    jest.spyOn(vm, 'getStagedFilesCountForPath', 'get').mockReturnValue(() => stagedFilesCount);
    jest.spyOn(vm, 'getChangesInFolder', 'get').mockReturnValue(() => changesCount);

    vm.$mount();
  });

  afterEach(() => {
    vm.$destroy();

    stagedFilesCount = 0;
    unstagedFilesCount = 0;
    changesCount = 0;
  });

  describe('folderChangesTooltip', () => {
    it('returns undefined when changes count is 0', () => {
      changesCount = 0;

      expect(vm.folderChangesTooltip).toBe(undefined);
    });

    [
      { input: 1, output: '1 changed file' },
      { input: 2, output: '2 changed files' },
    ].forEach(({ input, output }) => {
      it('returns changed files count if changes count is not 0', () => {
        changesCount = input;

        expect(vm.folderChangesTooltip).toBe(output);
      });
    });
  });

  describe('show tree changes count', () => {
    it('does not show for blobs', () => {
      vm.file.type = 'blob';

      expect(vm.$el.querySelector('.ide-tree-changes')).toBe(null);
    });

    it('does not show when changes count is 0', () => {
      vm.file.type = 'tree';

      expect(vm.$el.querySelector('.ide-tree-changes')).toBe(null);
    });

    it('does not show when tree is open', async () => {
      vm.file.type = 'tree';
      vm.file.opened = true;
      changesCount = 1;

      await nextTick();
      expect(vm.$el.querySelector('.ide-tree-changes')).toBe(null);
    });

    it('shows for trees with changes', async () => {
      vm.file.type = 'tree';
      vm.file.opened = false;
      changesCount = 1;

      await nextTick();
      expect(vm.$el.querySelector('.ide-tree-changes')).not.toBe(null);
    });
  });

  describe('changes file icon', () => {
    it('hides when file is not changed', () => {
      expect(vm.$el.querySelector('.file-changed-icon')).toBe(null);
    });

    it('shows when file is changed', async () => {
      vm.file.changed = true;

      await nextTick();
      expect(vm.$el.querySelector('.file-changed-icon')).not.toBe(null);
    });

    it('shows when file is staged', async () => {
      vm.file.staged = true;

      await nextTick();
      expect(vm.$el.querySelector('.file-changed-icon')).not.toBe(null);
    });

    it('shows when file is a tempFile', async () => {
      vm.file.tempFile = true;

      await nextTick();
      expect(vm.$el.querySelector('.file-changed-icon')).not.toBe(null);
    });

    it('shows when file is renamed', async () => {
      vm.file.prevPath = 'original-file';

      await nextTick();
      expect(vm.$el.querySelector('.file-changed-icon')).not.toBe(null);
    });

    it('hides when file is renamed', async () => {
      vm.file.prevPath = 'original-file';
      vm.file.type = 'tree';

      await nextTick();
      expect(vm.$el.querySelector('.file-changed-icon')).toBe(null);
    });
  });

  describe('merge request icon', () => {
    it('hides when not a merge request change', () => {
      expect(vm.$el.querySelector('[data-testid="git-merge-icon"]')).toBe(null);
    });

    it('shows when a merge request change', async () => {
      vm.file.mrChange = true;

      await nextTick();
      expect(vm.$el.querySelector('[data-testid="git-merge-icon"]')).not.toBe(null);
    });
  });
});
