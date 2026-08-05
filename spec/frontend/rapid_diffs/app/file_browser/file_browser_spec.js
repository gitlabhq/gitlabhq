import { shallowMount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import Vue, { nextTick } from 'vue';
import { PiniaVuePlugin } from 'pinia';
import FileBrowser from '~/rapid_diffs/app/file_browser/file_browser.vue';
import DiffsFileTree from '~/diffs/components/diffs_file_tree.vue';
import { useDiffsList } from '~/rapid_diffs/stores/diffs_list';
import { useFileBrowser } from '~/diffs/stores/file_browser';
import { useDiffsView } from '~/rapid_diffs/stores/diffs_view';

Vue.use(PiniaVuePlugin);

describe('FileBrowser', () => {
  let wrapper;
  let pinia;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(FileBrowser, {
      pinia,
      propsData: props,
    });
  };

  const findTree = () => wrapper.findComponent(DiffsFileTree);

  beforeEach(() => {
    pinia = createTestingPinia();
    useDiffsList();
    useDiffsView();
    useFileBrowser();
  });

  it('passes down props', () => {
    const loadedFiles = { foo: 1 };
    const totalFilesCount = 20;
    useDiffsList().loadedFiles = loadedFiles;
    useDiffsView().diffsStats = { diffsCount: totalFilesCount };
    createComponent();
    const tree = findTree();
    expect(tree.props('loadedFiles')).toStrictEqual(loadedFiles);
    expect(tree.props('totalFilesCount')).toStrictEqual(totalFilesCount);
    expect(tree.props('floatingResize')).toBe(true);
  });

  it('uses floating resize', () => {
    createComponent();
    expect(findTree().props('floatingResize')).toBe(true);
  });

  it('is visible by default', () => {
    createComponent();
    expect(findTree().exists()).toBe(true);
  });

  it('hides file browser', () => {
    useFileBrowser().fileBrowserVisible = false;
    createComponent();
    expect(findTree().exists()).toBe(false);
  });

  it('handles click', async () => {
    const file = { fileHash: 'foo' };
    createComponent();
    await findTree().vm.$emit('click-file', file);
    expect(wrapper.emitted('click-file')).toStrictEqual([[file]]);
  });

  it('handles toggle-folder', async () => {
    const path = 'foo';
    createComponent();
    await findTree().vm.$emit('toggle-folder', path);
    expect(useFileBrowser().toggleTreeOpen).toHaveBeenCalledWith(path);
  });

  describe('linkedFilePath prop', () => {
    it('passes linkedFilePath to DiffsFileTree', () => {
      createComponent({ linkedFilePath: 'path/to/file.txt' });
      expect(findTree().props('linkedFilePath')).toBe('path/to/file.txt');
    });

    it('passes null when linkedFilePath is not provided', () => {
      createComponent();
      expect(findTree().props('linkedFilePath')).toBeNull();
    });
  });

  describe('current file highlight', () => {
    beforeEach(() => {
      useFileBrowser().tree = [
        { type: 'blob', fileHash: 'first' },
        { type: 'blob', fileHash: 'second' },
      ];
    });

    it('reflects the clicked file when not in single-file mode', async () => {
      useDiffsView().singleFileMode = false;
      createComponent();
      expect(findTree().props('currentDiffFileId')).toBe('');
      await findTree().vm.$emit('click-file', { fileHash: 'second' });
      expect(findTree().props('currentDiffFileId')).toBe('second');
    });

    describe('in single-file mode', () => {
      beforeEach(() => {
        useDiffsView().singleFileMode = true;
      });

      it('tracks currentFileIndex regardless of prior click', async () => {
        useDiffsView().currentFileIndex = 0;
        createComponent();
        // simulate a stale click on a different file
        await findTree().vm.$emit('click-file', { fileHash: 'second' });
        expect(findTree().props('currentDiffFileId')).toBe('first');
      });

      it('updates the highlight when navigating to the next file', async () => {
        useDiffsView().currentFileIndex = 0;
        createComponent();
        expect(findTree().props('currentDiffFileId')).toBe('first');
        useDiffsView().currentFileIndex = 1;
        await nextTick();
        expect(findTree().props('currentDiffFileId')).toBe('second');
      });

      it('falls back to empty string for an out-of-range index', () => {
        useDiffsView().currentFileIndex = 5;
        createComponent();
        expect(findTree().props('currentDiffFileId')).toBe('');
      });
    });
  });
});
