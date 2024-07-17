// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { mount } from '@vue/test-utils';
import FileRowExtra from '~/ide/components/file_row_extra.vue';
import { createStoreOptions } from '~/ide/stores';
import { file } from '../helpers';

describe('IDE extra file row component', () => {
  let wrapper;
  let store;
  let unstagedFilesCount = 0;
  let stagedFilesCount = 0;
  let changesCount = 0;

  const createComponent = (fileProps) => {
    const storeConfig = createStoreOptions();

    store = new Vuex.Store({
      ...storeConfig,
      getters: {
        getUnstagedFilesCountForPath: () => () => unstagedFilesCount,
        getStagedFilesCountForPath: () => () => stagedFilesCount,
        getChangesInFolder: () => () => changesCount,
      },
    });

    wrapper = mount(FileRowExtra, {
      store,
      propsData: {
        file: {
          ...file('test'),
          type: 'tree',
          ...fileProps,
        },
        dropdownOpen: false,
      },
    });
  };

  afterEach(() => {
    stagedFilesCount = 0;
    unstagedFilesCount = 0;
    changesCount = 0;
  });

  describe('folder changes tooltip', () => {
    [
      { input: 1, output: '1 changed file' },
      { input: 2, output: '2 changed files' },
    ].forEach(({ input, output }) => {
      it('shows changed files count if changes count is not 0', () => {
        changesCount = input;
        createComponent();

        expect(wrapper.find('.ide-file-modified').attributes('title')).toBe(output);
      });
    });
  });

  describe('show tree changes count', () => {
    const findTreeChangesCount = () => wrapper.find('.ide-tree-changes');

    it('does not show for blobs', () => {
      createComponent({ type: 'blob' });

      expect(findTreeChangesCount().exists()).toBe(false);
    });

    it('does not show when changes count is 0', () => {
      createComponent({ type: 'tree' });

      expect(findTreeChangesCount().exists()).toBe(false);
    });

    it('does not show when tree is open', () => {
      changesCount = 1;
      createComponent({ type: 'tree', opened: true });

      expect(findTreeChangesCount().exists()).toBe(false);
    });

    it('shows for trees with changes', () => {
      changesCount = 1;
      createComponent({ type: 'tree', opened: false });

      expect(findTreeChangesCount().exists()).toBe(true);
    });
  });

  describe('changes file icon', () => {
    const findChangedFileIcon = () => wrapper.find('.file-changed-icon');

    it('hides when file is not changed', () => {
      createComponent();

      expect(findChangedFileIcon().exists()).toBe(false);
    });

    it('shows when file is changed', () => {
      createComponent({ type: 'blob', changed: true });

      expect(findChangedFileIcon().exists()).toBe(true);
    });

    it('shows when file is staged', () => {
      createComponent({ type: 'blob', staged: true });

      expect(findChangedFileIcon().exists()).toBe(true);
    });

    it('shows when file is a tempFile', () => {
      createComponent({ type: 'blob', tempFile: true });

      expect(findChangedFileIcon().exists()).toBe(true);
    });

    it('shows when file is renamed', () => {
      createComponent({ type: 'blob', prevPath: 'original-file' });

      expect(findChangedFileIcon().exists()).toBe(true);
    });

    it('hides when tree is renamed', () => {
      createComponent({ type: 'tree', prevPath: 'original-path' });

      expect(findChangedFileIcon().exists()).toBe(false);
    });
  });

  describe('merge request icon', () => {
    const findMergeRequestIcon = () => wrapper.find('[data-testid="merge-request-icon"]');

    it('hides when not a merge request change', () => {
      createComponent();

      expect(findMergeRequestIcon().exists()).toBe(false);
    });

    it('shows when a merge request change', () => {
      createComponent({ mrChange: true });

      expect(findMergeRequestIcon().exists()).toBe(true);
    });
  });
});
