import { GlCollapsibleListbox } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';

import SettingsDropdown from '~/diffs/components/settings_dropdown.vue';
import { PARALLEL_DIFF_VIEW_TYPE, INLINE_DIFF_VIEW_TYPE } from '~/diffs/constants';
import eventHub from '~/diffs/event_hub';
import store from '~/mr_notes/stores';

jest.mock('~/mr_notes/stores', () => jest.requireActual('helpers/mocks/mr_notes/stores'));

describe('Diff settings dropdown component', () => {
  let wrapper;

  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findInlineListItem = () => wrapper.findByTestId('listbox-item-inline');
  const findInlineListItemCheckbox = () =>
    findInlineListItem().find('[data-testid="dropdown-item-checkbox"]');
  const findParallelListItem = () => wrapper.findByTestId('listbox-item-parallel');
  const findParallelListItemCheckbox = () =>
    findParallelListItem().find('[data-testid="dropdown-item-checkbox"]');

  const createComponent = () =>
    mountExtended(SettingsDropdown, {
      mocks: {
        $store: store,
      },
    });

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

      wrapper = createComponent();

      expect(findInlineListItemCheckbox().classes()).not.toContain('gl-invisible');
      expect(findParallelListItemCheckbox().classes()).toContain('gl-invisible');
    });

    it('sets parallel button as selected', () => {
      store.state.diffs = { diffViewType: PARALLEL_DIFF_VIEW_TYPE };
      store.getters['diffs/isParallelView'] = true;

      wrapper = createComponent();

      expect(findInlineListItemCheckbox().classes()).toContain('gl-invisible');
      expect(findParallelListItemCheckbox().classes()).not.toContain('gl-invisible');
    });

    it('calls setDiffViewType when clicking inline button', () => {
      wrapper = createComponent();

      findDropdown().vm.$emit('select', 'inline');

      expect(store.dispatch).toHaveBeenCalledWith('diffs/setDiffViewType', INLINE_DIFF_VIEW_TYPE);
    });

    it('calls setDiffViewType when clicking parallel button', () => {
      wrapper = createComponent();

      findDropdown().vm.$emit('select', 'parallel');

      expect(store.dispatch).toHaveBeenCalledWith('diffs/setDiffViewType', PARALLEL_DIFF_VIEW_TYPE);
    });
  });

  describe('whitespace toggle', () => {
    it('does not set as checked when showWhitespace is false', () => {
      store.state.diffs = { showWhitespace: false };

      wrapper = createComponent();

      expect(wrapper.findByTestId('show-whitespace').element.checked).toBe(false);
    });

    it('sets as checked when showWhitespace is true', () => {
      store.state.diffs = { showWhitespace: true };

      wrapper = createComponent();

      expect(wrapper.findByTestId('show-whitespace').element.checked).toBe(true);
    });

    it('calls setShowWhitespace on change', async () => {
      wrapper = createComponent();
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

        wrapper = createComponent();

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

        wrapper = createComponent();
        await getFileByFileCheckbox(wrapper).setChecked(setting);

        expect(store.dispatch).toHaveBeenCalledWith('diffs/setFileByFile', {
          fileByFile: setting,
        });
      },
    );
  });
});
