import { shallowMount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import Vue, { nextTick } from 'vue';
import { PiniaVuePlugin } from 'pinia';
import { GlDrawer } from '@gitlab/ui';
import FileBrowserDrawer from '~/rapid_diffs/app/file_browser/file_browser_drawer.vue';
import DiffsFileTree from '~/diffs/components/diffs_file_tree.vue';
import { useDiffsList } from '~/rapid_diffs/stores/diffs_list';
import { useFileBrowser } from '~/diffs/stores/file_browser';
import { useDiffsView } from '~/rapid_diffs/stores/diffs_view';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';

Vue.use(PiniaVuePlugin);

describe('FileBrowserDrawer', () => {
  let wrapper;
  let pinia;

  const createComponent = () => {
    wrapper = shallowMount(FileBrowserDrawer, {
      pinia,
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
  });

  it('is hidden by default', () => {
    createComponent();
    expect(wrapper.findComponent(GlDrawer).props('open')).toBe(false);
  });

  it('shows file browser', async () => {
    createComponent();
    useFileBrowser().fileBrowserDrawerVisible = true;
    await nextTick();
    expect(wrapper.findComponent(GlDrawer).props('open')).toBe(true);
  });

  it('handles click', async () => {
    const file = { fileHash: 'foo' };
    createComponent();
    await wrapper.findComponent(DiffsFileTree).vm.$emit('clickFile', file);
    expect(wrapper.emitted('clickFile')).toStrictEqual([[file]]);
    expect(useFileBrowser().setFileBrowserDrawerVisibility).toHaveBeenCalledWith(false);
  });

  it('updates state on destroy', () => {
    createComponent();
    wrapper.destroy();
    expect(useFileBrowser().setFileBrowserDrawerVisibility).toHaveBeenCalledWith(false);
  });

  it('handles toggleFolder', async () => {
    const path = 'foo';
    createComponent();
    await wrapper.findComponent(DiffsFileTree).vm.$emit('toggleFolder', path);
    expect(useLegacyDiffs().toggleTreeOpen).toHaveBeenCalledWith(path);
  });
});
