import { shallowMount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import Vue, { nextTick } from 'vue';
import { PiniaVuePlugin } from 'pinia';
import FileBrowser from '~/rapid_diffs/app/file_browser.vue';
import DiffsFileTree from '~/diffs/components/diffs_file_tree.vue';
import store from '~/mr_notes/stores';
import { useDiffsList } from '~/rapid_diffs/stores/diffs_list';
import { useFileBrowser } from '~/diffs/stores/file_browser';

Vue.use(PiniaVuePlugin);

describe('FileBrowser', () => {
  let wrapper;

  const createComponent = () => {
    const pinia = createTestingPinia();
    useDiffsList();
    useFileBrowser();
    wrapper = shallowMount(FileBrowser, {
      store,
      pinia,
    });
  };

  it('passes down loaded files', async () => {
    const loadedFiles = { foo: 1 };
    createComponent();
    useDiffsList().loadedFiles = loadedFiles;
    await nextTick();
    expect(wrapper.findComponent(DiffsFileTree).props('loadedFiles')).toStrictEqual(loadedFiles);
  });

  it('is visible by default', () => {
    createComponent();
    expect(wrapper.findComponent(DiffsFileTree).exists()).toBe(true);
  });

  it('hides file browser', async () => {
    createComponent();
    useFileBrowser().fileBrowserVisible = false;
    await nextTick();
    expect(wrapper.findComponent(DiffsFileTree).exists()).toBe(false);
  });

  it('handles click', async () => {
    const file = { fileHash: 'foo' };
    createComponent();
    await wrapper.findComponent(DiffsFileTree).vm.$emit('clickFile', file);
    expect(wrapper.emitted('clickFile')).toStrictEqual([[file]]);
  });
});
