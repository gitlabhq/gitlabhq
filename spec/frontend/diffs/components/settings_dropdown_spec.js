import { mount } from '@vue/test-utils';

import { extendedWrapper } from 'helpers/vue_test_utils_helper';

import SettingsDropdown from '~/diffs/components/settings_dropdown.vue';
import { PARALLEL_DIFF_VIEW_TYPE, INLINE_DIFF_VIEW_TYPE } from '~/diffs/constants';
import eventHub from '~/diffs/event_hub';

import createDiffsStore from '../create_diffs_store';

describe('Diff settings dropdown component', () => {
  let wrapper;
  let vm;
  let store;

  function createComponent(extendStore = () => {}) {
    store = createDiffsStore();

    extendStore(store);

    wrapper = extendedWrapper(
      mount(SettingsDropdown, {
        store,
      }),
    );
    vm = wrapper.vm;
  }

  function getFileByFileCheckbox(vueWrapper) {
    return vueWrapper.findByTestId('file-by-file');
  }

  function setup({ storeUpdater } = {}) {
    createComponent(storeUpdater);
    jest.spyOn(store, 'dispatch').mockImplementation(() => {});
  }

  beforeEach(() => {
    setup();
  });

  afterEach(() => {
    store.dispatch.mockRestore();
    wrapper.destroy();
  });

  describe('tree view buttons', () => {
    it('list view button dispatches setRenderTreeList with false', () => {
      wrapper.find('.js-list-view').trigger('click');

      expect(store.dispatch).toHaveBeenCalledWith('diffs/setRenderTreeList', false);
    });

    it('tree view button dispatches setRenderTreeList with true', () => {
      wrapper.find('.js-tree-view').trigger('click');

      expect(store.dispatch).toHaveBeenCalledWith('diffs/setRenderTreeList', true);
    });

    it('sets list button as selected when renderTreeList is false', () => {
      setup({
        storeUpdater: (origStore) =>
          Object.assign(origStore.state.diffs, { renderTreeList: false }),
      });

      expect(wrapper.find('.js-list-view').classes('selected')).toBe(true);
      expect(wrapper.find('.js-tree-view').classes('selected')).toBe(false);
    });

    it('sets tree button as selected when renderTreeList is true', () => {
      setup({
        storeUpdater: (origStore) => Object.assign(origStore.state.diffs, { renderTreeList: true }),
      });

      expect(wrapper.find('.js-list-view').classes('selected')).toBe(false);
      expect(wrapper.find('.js-tree-view').classes('selected')).toBe(true);
    });
  });

  describe('compare changes', () => {
    it('sets inline button as selected', () => {
      setup({
        storeUpdater: (origStore) =>
          Object.assign(origStore.state.diffs, { diffViewType: INLINE_DIFF_VIEW_TYPE }),
      });

      expect(wrapper.find('.js-inline-diff-button').classes('selected')).toBe(true);
      expect(wrapper.find('.js-parallel-diff-button').classes('selected')).toBe(false);
    });

    it('sets parallel button as selected', () => {
      setup({
        storeUpdater: (origStore) =>
          Object.assign(origStore.state.diffs, { diffViewType: PARALLEL_DIFF_VIEW_TYPE }),
      });

      expect(wrapper.find('.js-inline-diff-button').classes('selected')).toBe(false);
      expect(wrapper.find('.js-parallel-diff-button').classes('selected')).toBe(true);
    });

    it('calls setInlineDiffViewType when clicking inline button', () => {
      wrapper.find('.js-inline-diff-button').trigger('click');

      expect(store.dispatch).toHaveBeenCalledWith('diffs/setInlineDiffViewType', expect.anything());
    });

    it('calls setParallelDiffViewType when clicking parallel button', () => {
      wrapper.find('.js-parallel-diff-button').trigger('click');

      expect(store.dispatch).toHaveBeenCalledWith(
        'diffs/setParallelDiffViewType',
        expect.anything(),
      );
    });
  });

  describe('whitespace toggle', () => {
    it('does not set as checked when showWhitespace is false', () => {
      setup({
        storeUpdater: (origStore) =>
          Object.assign(origStore.state.diffs, { showWhitespace: false }),
      });

      expect(wrapper.findByTestId('show-whitespace').element.checked).toBe(false);
    });

    it('sets as checked when showWhitespace is true', () => {
      setup({
        storeUpdater: (origStore) => Object.assign(origStore.state.diffs, { showWhitespace: true }),
      });

      expect(wrapper.findByTestId('show-whitespace').element.checked).toBe(true);
    });

    it('calls setShowWhitespace on change', async () => {
      const checkbox = wrapper.findByTestId('show-whitespace');
      const { checked } = checkbox.element;

      checkbox.trigger('click');

      await vm.$nextTick();

      expect(store.dispatch).toHaveBeenCalledWith('diffs/setShowWhitespace', {
        showWhitespace: !checked,
      });
    });
  });

  describe('file-by-file toggle', () => {
    beforeEach(() => {
      jest.spyOn(eventHub, '$emit');
    });

    it.each`
      fileByFile | checked
      ${true}    | ${true}
      ${false}   | ${false}
    `(
      'sets the checkbox to { checked: $checked } if the fileByFile setting is $fileByFile',
      ({ fileByFile, checked }) => {
        setup({
          storeUpdater: (origStore) =>
            Object.assign(origStore.state.diffs, { viewDiffsFileByFile: fileByFile }),
        });

        expect(getFileByFileCheckbox(wrapper).element.checked).toBe(checked);
      },
    );

    it.each`
      start    | setting
      ${true}  | ${false}
      ${false} | ${true}
    `(
      'when the file by file setting starts as $start, toggling the checkbox should call setFileByFile with $setting',
      async ({ start, setting }) => {
        setup({
          storeUpdater: (origStore) =>
            Object.assign(origStore.state.diffs, { viewDiffsFileByFile: start }),
        });

        getFileByFileCheckbox(wrapper).trigger('click');

        await vm.$nextTick();

        expect(store.dispatch).toHaveBeenCalledWith('diffs/setFileByFile', {
          fileByFile: setting,
        });
      },
    );
  });
});
