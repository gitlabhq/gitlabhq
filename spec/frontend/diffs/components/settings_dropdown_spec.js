import { GlCollapsibleListbox } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SettingsDropdown from '~/diffs/components/settings_dropdown.vue';

const defaultProps = {
  diffViewType: 'inline',
};

describe('Diff settings dropdown component', () => {
  let wrapper;

  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findWhitespaceCheckbox = () => wrapper.findByTestId('show-whitespace');
  const findFileByFileCheckbox = () => wrapper.findByTestId('file-by-file');

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

    it('emits updateDiffViewType event', () => {
      createComponent();
      findDropdown().vm.$emit('select', 'inline');
      expect(wrapper.emitted('updateDiffViewType')).toEqual([['inline']]);
    });
  });

  describe('whitespace toggle', () => {
    it('does not set as checked when showWhitespace is false', () => {
      createComponent({ showWhitespace: false });
      // https://gitlab.com/gitlab-org/gitlab-ui/-/issues/3033
      // GlFormCheckbox is missing checked prop and doesn't inherit attrs
      // We can only check against its internal state unfortunately
      expect(findWhitespaceCheckbox().vm.$attrs.checked).toBe(false);
    });

    it('sets as checked when showWhitespace is true', () => {
      createComponent({ showWhitespace: true });
      expect(findWhitespaceCheckbox().vm.$attrs.checked).toBe(true);
    });

    it('emits toggleWhitespace event', () => {
      createComponent();
      findWhitespaceCheckbox().vm.$emit('input', false);
      expect(wrapper.emitted('toggleWhitespace')).toEqual([[false]]);
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
        expect(findFileByFileCheckbox().vm.$attrs.checked).toBe(checked);
      },
    );

    it.each`
      viewDiffsFileByFile | eventValue
      ${true}             | ${false}
      ${false}            | ${true}
    `(
      'emits toggleFileByFile event with $setting value when viewDiffsFileByFile is $viewDiffsFileByFile',
      ({ viewDiffsFileByFile, eventValue }) => {
        createComponent({ viewDiffsFileByFile });
        findFileByFileCheckbox().vm.$emit('input', eventValue);
        expect(wrapper.emitted('toggleFileByFile')).toEqual([[eventValue]]);
      },
    );
  });
});
