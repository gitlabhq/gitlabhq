import { GlCollapsibleListbox } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SettingsDropdown from '~/diffs/components/settings_dropdown.vue';

const defaultProps = {
  diffViewType: 'inline',
  showWhitespace: false,
};

describe('Diff settings dropdown component', () => {
  let wrapper;

  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findWhitespaceCheckbox = () => wrapper.findComponentByTestId('show-whitespace');
  const findFileByFileCheckbox = () => wrapper.findComponentByTestId('file-by-file');

  const createComponent = (propsData) => {
    wrapper = shallowMountExtended(SettingsDropdown, {
      propsData: {
        ...defaultProps,
        ...propsData,
      },
    });
  };

  describe('compare changes', () => {
    it('sets inline button as selected', () => {
      createComponent();
      expect(findDropdown().props('selected')).toBe('inline');
    });

    it('sets parallel button as selected', () => {
      createComponent({ diffViewType: 'parallel' });
      expect(findDropdown().props('selected')).toBe('parallel');
    });

    it('emits update-diff-view-type event', () => {
      createComponent();
      findDropdown().vm.$emit('select', 'inline');
      expect(wrapper.emitted('update-diff-view-type')).toEqual([['inline']]);
    });
  });

  describe('whitespace toggle', () => {
    it('does not set as checked when showWhitespace is false', () => {
      createComponent({ showWhitespace: false });
      expect(findWhitespaceCheckbox().props('checked')).toBe(false);
    });

    it('sets as checked when showWhitespace is true', () => {
      createComponent({ showWhitespace: true });
      expect(findWhitespaceCheckbox().props('checked')).toBe(true);
    });

    it('emits toggle-whitespace event', () => {
      createComponent();
      findWhitespaceCheckbox().vm.$emit('input', false);
      expect(wrapper.emitted('toggle-whitespace')).toEqual([[false]]);
    });
  });

  describe('file-by-file toggle', () => {
    it.each`
      fileByFile | checked
      ${true}    | ${true}
      ${false}   | ${false}
    `(
      'sets the checkbox to { checked: $checked } if the fileByFile setting is $fileByFile',
      ({ fileByFile, checked }) => {
        createComponent({ viewDiffsFileByFile: fileByFile });
        expect(findFileByFileCheckbox().props('checked')).toBe(checked);
      },
    );

    it.each`
      viewDiffsFileByFile | eventValue
      ${true}             | ${false}
      ${false}            | ${true}
    `(
      'emits toggle-file-by-file event with $setting value when viewDiffsFileByFile is $viewDiffsFileByFile',
      ({ viewDiffsFileByFile, eventValue }) => {
        createComponent({ viewDiffsFileByFile });
        findFileByFileCheckbox().vm.$emit('input', eventValue);
        expect(wrapper.emitted('toggle-file-by-file')).toEqual([[eventValue]]);
      },
    );

    it('can be hidden', () => {
      createComponent({ fileByFileSupported: false });
      expect(findFileByFileCheckbox().exists()).toBe(false);
    });
  });
});
