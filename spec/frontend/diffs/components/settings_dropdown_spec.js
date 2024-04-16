import { mount } from '@vue/test-utils';

import { extendedWrapper } from 'helpers/vue_test_utils_helper';

import SettingsDropdown from '~/diffs/components/settings_dropdown.vue';
import { PARALLEL_DIFF_VIEW_TYPE, INLINE_DIFF_VIEW_TYPE } from '~/diffs/constants';
import eventHub from '~/diffs/event_hub';
import store from '~/mr_notes/stores';

jest.mock('~/mr_notes/stores', () => jest.requireActual('helpers/mocks/mr_notes/stores'));

describe('Diff settings dropdown component', () => {
  const createComponent = () =>
    extendedWrapper(
      mount(SettingsDropdown, {
        mocks: {
          $store: store,
        },
      }),
    );

  function getFileByFileCheckbox(vueWrapper) {
    return vueWrapper.findByTestId('file-by-file');
  }

  beforeEach(() => {
    store.reset();

    store.getters['diffs/isInlineView'] = false;
    store.getters['diffs/isParallelView'] = false;
  });

  describe('compare changes', () => {
    it('sets inline button as selected', () => {
      store.state.diffs = { diffViewType: INLINE_DIFF_VIEW_TYPE };
      store.getters['diffs/isInlineView'] = true;

      const wrapper = createComponent();

      expect(wrapper.find('.js-inline-diff-button').classes('selected')).toBe(true);
      expect(wrapper.find('.js-parallel-diff-button').classes('selected')).toBe(false);
    });

    it('sets parallel button as selected', () => {
      store.state.diffs = { diffViewType: PARALLEL_DIFF_VIEW_TYPE };
      store.getters['diffs/isParallelView'] = true;

      const wrapper = createComponent();

      expect(wrapper.find('.js-inline-diff-button').classes('selected')).toBe(false);
      expect(wrapper.find('.js-parallel-diff-button').classes('selected')).toBe(true);
    });

    it('calls setInlineDiffViewType when clicking inline button', () => {
      const wrapper = createComponent();

      wrapper.find('.js-inline-diff-button').trigger('click');

      expect(store.dispatch).toHaveBeenCalledWith('diffs/setInlineDiffViewType', expect.anything());
    });

    it('calls setParallelDiffViewType when clicking parallel button', () => {
      const wrapper = createComponent();

      wrapper.find('.js-parallel-diff-button').trigger('click');

      expect(store.dispatch).toHaveBeenCalledWith(
        'diffs/setParallelDiffViewType',
        expect.anything(),
      );
    });
  });

  describe('whitespace toggle', () => {
    it('does not set as checked when showWhitespace is false', () => {
      store.state.diffs = { showWhitespace: false };

      const wrapper = createComponent();

      expect(wrapper.findByTestId('show-whitespace').element.checked).toBe(false);
    });

    it('sets as checked when showWhitespace is true', () => {
      store.state.diffs = { showWhitespace: true };

      const wrapper = createComponent();

      expect(wrapper.findByTestId('show-whitespace').element.checked).toBe(true);
    });

    it('calls setShowWhitespace on change', async () => {
      const wrapper = createComponent();
      const checkbox = wrapper.findByTestId('show-whitespace');
      const { checked } = checkbox.element;

      await checkbox.setChecked(false);

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
        store.state.diffs = { viewDiffsFileByFile: fileByFile };

        const wrapper = createComponent();

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
        store.state.diffs = { viewDiffsFileByFile: start };

        const wrapper = createComponent();
        await getFileByFileCheckbox(wrapper).setChecked(setting);

        expect(store.dispatch).toHaveBeenCalledWith('diffs/setFileByFile', {
          fileByFile: setting,
        });
      },
    );
  });
});
