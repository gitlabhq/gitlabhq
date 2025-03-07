import { shallowMount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import Vue, { nextTick } from 'vue';
import { PiniaVuePlugin } from 'pinia';
import FileBrowser from '~/rapid_diffs/app/file_browser.vue';
import DiffsFileTree from '~/diffs/components/diffs_file_tree.vue';
import store from '~/mr_notes/stores';
import * as types from '~/diffs/store/mutation_types';
import { useDiffsList } from '~/rapid_diffs/stores/diffs_list';

Vue.use(PiniaVuePlugin);

describe('FileBrowser', () => {
  let wrapper;
  let commit;

  const createComponent = () => {
    const pinia = createTestingPinia();
    useDiffsList();
    wrapper = shallowMount(FileBrowser, {
      store,
      pinia,
    });
  };

  beforeEach(() => {
    commit = jest.spyOn(store, 'commit');
  });

  it('passes down loaded files', async () => {
    const loadedFiles = { foo: 1 };
    createComponent();
    useDiffsList().loadedFiles = loadedFiles;
    await nextTick();
    expect(wrapper.findComponent(DiffsFileTree).props('loadedFiles')).toStrictEqual(loadedFiles);
  });

  it('is visible by default', () => {
    createComponent();
    expect(wrapper.findComponent(DiffsFileTree).props('visible')).toBe(true);
  });

  it('toggles visibility', async () => {
    createComponent();
    await wrapper.findComponent(DiffsFileTree).vm.$emit('toggled');
    expect(wrapper.findComponent(DiffsFileTree).props('visible')).toBe(false);
  });

  it('handles click', async () => {
    const file = { fileHash: 'foo' };
    createComponent();
    await wrapper.findComponent(DiffsFileTree).vm.$emit('clickFile', file);
    expect(wrapper.emitted('clickFile')).toStrictEqual([[file]]);
    expect(commit).toHaveBeenCalledWith(
      `diffs/${types.SET_CURRENT_DIFF_FILE}`,
      file.fileHash,
      undefined,
    );
  });
});
