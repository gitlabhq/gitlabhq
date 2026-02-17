import { shallowMount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import Vue from 'vue';
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
    const tree = wrapper.findComponent(DiffsFileTree);
    expect(tree.props('loadedFiles')).toStrictEqual(loadedFiles);
    expect(tree.props('totalFilesCount')).toStrictEqual(totalFilesCount);
    expect(tree.props('floatingResize')).toBe(true);
  });

  it('uses floating resize', () => {
    createComponent();
    expect(wrapper.findComponent(DiffsFileTree).props('floatingResize')).toBe(true);
  });

  it('is visible by default', () => {
    createComponent();
    expect(wrapper.findComponent(DiffsFileTree).exists()).toBe(true);
  });

  it('hides file browser', () => {
    useFileBrowser().fileBrowserVisible = false;
    createComponent();
    expect(wrapper.findComponent(DiffsFileTree).exists()).toBe(false);
  });

  it('handles click', async () => {
    const file = { fileHash: 'foo' };
    createComponent();
    await wrapper.findComponent(DiffsFileTree).vm.$emit('clickFile', file);
    expect(wrapper.emitted('clickFile')).toStrictEqual([[file]]);
  });

  it('handles toggleFolder', async () => {
    const path = 'foo';
    createComponent();
    await wrapper.findComponent(DiffsFileTree).vm.$emit('toggleFolder', path);
    expect(useFileBrowser().toggleTreeOpen).toHaveBeenCalledWith(path);
  });

  describe('linkedFilePath prop', () => {
    it('passes linkedFilePath to DiffsFileTree', () => {
      createComponent({ linkedFilePath: 'path/to/file.txt' });
      expect(wrapper.findComponent(DiffsFileTree).props('linkedFilePath')).toBe('path/to/file.txt');
    });

    it('passes null when linkedFilePath is not provided', () => {
      createComponent();
      expect(wrapper.findComponent(DiffsFileTree).props('linkedFilePath')).toBeNull();
    });
  });
});
