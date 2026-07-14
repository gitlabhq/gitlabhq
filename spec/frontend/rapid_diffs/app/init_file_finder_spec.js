import { createTestingPinia } from '@pinia/testing';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { useFileBrowser } from '~/diffs/stores/file_browser';
import { DiffFile } from '~/rapid_diffs/web_components/diff_file';
import { initFileFinder } from '~/rapid_diffs/app/init_file_finder';

jest.mock('~/vue_shared/components/file_finder/index.vue', () => ({
  name: 'FindFile',
  props: {
    files: { type: Array, required: true },
    visible: { type: Boolean, required: true },
    loading: { type: Boolean, required: true },
    showDiffStats: { type: Boolean, default: false },
    clearSearchOnClose: { type: Boolean, default: true },
  },
  render(h) {
    return h('div', { attrs: { 'data-testid': 'mock-find-file' } }, [
      h('button', {
        attrs: { 'data-testid': 'mock-toggle' },
        on: { click: () => this.$emit('toggle', !this.visible) },
      }),
      h('button', {
        attrs: { 'data-testid': 'mock-click-file' },
        on: {
          click: () => this.$emit('click', { fileHash: 'abc123', path: 'foo.js', name: 'foo.js' }),
        },
      }),
    ]);
  },
}));

const findFileFinder = () => document.querySelector('[data-testid="mock-find-file"]');

describe('initFileFinder', () => {
  beforeEach(() => {
    createTestingPinia({ stubActions: false });
    setHTMLFixture('<div id="js-diff-file-finder"></div>');
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('mounts the file finder on the target element', () => {
    initFileFinder();

    expect(findFileFinder()).not.toBeNull();
  });

  it('does nothing when the mount element is absent', () => {
    resetHTMLFixture();

    expect(() => initFileFinder()).not.toThrow();
  });

  it('navigates to the selected file when the component emits click', () => {
    const selectFile = jest.fn();
    jest.spyOn(DiffFile, 'findByFileHash').mockReturnValue({ selectFile });

    initFileFinder();
    document.querySelector('[data-testid="mock-click-file"]').click();

    expect(DiffFile.findByFileHash).toHaveBeenCalledWith('abc123');
    expect(selectFile).toHaveBeenCalled();
  });

  it('does not throw when the diff file is not found', () => {
    jest.spyOn(DiffFile, 'findByFileHash').mockReturnValue(null);

    const vm = initFileFinder();

    expect(() => vm.openFile({ fileHash: 'missing', path: 'gone.js' })).not.toThrow();
  });

  it('toggles visibility when the component emits toggle', () => {
    const vm = initFileFinder();
    expect(vm.visible).toBe(false);

    document.querySelector('[data-testid="mock-toggle"]').click();
    expect(vm.visible).toBe(true);
  });

  it('passes loading state from the file browser store', () => {
    useFileBrowser().isLoadingFileBrowser = true;

    const vm = initFileFinder();

    expect(vm.isLoadingFileBrowser).toBe(true);
  });
});
