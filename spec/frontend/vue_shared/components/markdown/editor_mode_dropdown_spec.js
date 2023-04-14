import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import EditorModeDropdown from '~/vue_shared/components/markdown/editor_mode_dropdown.vue';

describe('vue_shared/component/markdown/editor_mode_dropdown', () => {
  let wrapper;

  const createComponent = ({ value, size } = {}) => {
    wrapper = shallowMount(EditorModeDropdown, {
      propsData: {
        value,
        size,
      },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownItem = (text) =>
    wrapper
      .findAllComponents(GlDropdownItem)
      .filter((item) => item.text().startsWith(text))
      .at(0);

  describe.each`
    modeText       | value         | dropdownText           | otherMode
    ${'Rich text'} | ${'richText'} | ${'Editing rich text'} | ${'Markdown'}
    ${'Markdown'}  | ${'markdown'} | ${'Editing markdown'}  | ${'Rich text'}
  `('$modeText', ({ modeText, value, dropdownText, otherMode }) => {
    beforeEach(() => {
      createComponent({ value });
    });

    it('shows correct dropdown label', () => {
      expect(findDropdown().props('text')).toEqual(dropdownText);
    });

    it('checks correct checked dropdown item', () => {
      expect(findDropdownItem(modeText).props().isChecked).toBe(true);
      expect(findDropdownItem(otherMode).props().isChecked).toBe(false);
    });

    it('emits event on click', () => {
      findDropdownItem(modeText).vm.$emit('click');

      expect(wrapper.emitted().input).toEqual([[value]]);
    });
  });

  it('passes size to dropdown', () => {
    createComponent({ size: 'small', value: 'markdown' });

    expect(findDropdown().props('size')).toEqual('small');
  });
});
