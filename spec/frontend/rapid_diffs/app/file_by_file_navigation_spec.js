import Vue from 'vue';
import { GlKeysetPagination } from '@gitlab/ui';
import { PiniaVuePlugin } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { useFileBrowser } from '~/diffs/stores/file_browser';
import FileByFileNavigation from '~/rapid_diffs/app/file_by_file_navigation.vue';
import { useDiffsView } from '~/rapid_diffs/stores/diffs_view';

Vue.use(PiniaVuePlugin);

describe('FileByFileNavigation', () => {
  let wrapper;
  let pinia;

  const files = [
    { type: 'blob', filePaths: { old: 'a.js', new: 'a.js' }, fileHash: 'aaa' },
    { type: 'blob', filePaths: { old: 'b.js', new: 'b.js' }, fileHash: 'bbb' },
    { type: 'blob', filePaths: { old: 'c.js', new: 'c.js' }, fileHash: 'ccc' },
  ];

  const createComponent = ({ singleFileMode = true, currentFileIndex = 0 } = {}) => {
    pinia = createTestingPinia();
    useDiffsView().$patch({ singleFileMode, currentFileIndex });
    useFileBrowser().tree = files;
    wrapper = shallowMountExtended(FileByFileNavigation, { pinia });
  };

  const findPagination = () => wrapper.findComponent(GlKeysetPagination);
  const findNavigation = () => wrapper.findByTestId('file-by-file-navigation');

  it('renders when in single file mode with multiple files', () => {
    createComponent();
    expect(findNavigation().exists()).toBe(true);
  });

  it('does not render when not in single file mode', () => {
    createComponent({ singleFileMode: false });
    expect(findNavigation().exists()).toBe(false);
  });

  it('does not render when there is only one file', () => {
    pinia = createTestingPinia();
    useDiffsView().$patch({ singleFileMode: true, currentFileIndex: 0 });
    useFileBrowser().tree = [files[0]];
    wrapper = shallowMountExtended(FileByFileNavigation, { pinia });
    expect(findNavigation().exists()).toBe(false);
  });

  it('passes file count message to GlSprintf', () => {
    createComponent({ currentFileIndex: 1 });
    const sprintf = wrapper.findComponent({ name: 'GlSprintf' });
    expect(sprintf.attributes('message')).toBe('File %{current} of %{total}');
  });

  it('passes correct page info to pagination', () => {
    createComponent({ currentFileIndex: 1 });
    expect(findPagination().props('hasPreviousPage')).toBe(true);
    expect(findPagination().props('hasNextPage')).toBe(true);
  });

  it('disables prev at the first file', () => {
    createComponent({ currentFileIndex: 0 });
    expect(findPagination().props('hasPreviousPage')).toBe(false);
    expect(findPagination().props('hasNextPage')).toBe(true);
  });

  it('disables next at the last file', () => {
    createComponent({ currentFileIndex: 2 });
    expect(findPagination().props('hasPreviousPage')).toBe(true);
    expect(findPagination().props('hasNextPage')).toBe(false);
  });

  it('calls goToNextFile on next', () => {
    createComponent();
    findPagination().vm.$emit('next');
    expect(useDiffsView().goToNextFile).toHaveBeenCalled();
  });

  it('calls goToPrevFile on prev', () => {
    createComponent({ currentFileIndex: 1 });
    findPagination().vm.$emit('prev');
    expect(useDiffsView().goToPrevFile).toHaveBeenCalled();
  });
});
