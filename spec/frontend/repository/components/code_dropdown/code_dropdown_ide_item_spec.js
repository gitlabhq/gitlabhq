import { shallowMount } from '@vue/test-utils';
import { GlButton, GlButtonGroup, GlDisclosureDropdownItem } from '@gitlab/ui';
import CodeDropdownIdeItem from '~/repository/components/code_dropdown/code_dropdown_ide_item.vue';

describe('CodeDropdownIdeItem', () => {
  let wrapper;

  const findButtonGroup = () => wrapper.findComponent(GlButtonGroup);
  const findAllGlButtons = () => wrapper.findAllComponents(GlButton);
  const findGlButtonAtIndex = (index) => findAllGlButtons().at(index);
  const findDropdownItems = () => wrapper.findAllComponents(GlDisclosureDropdownItem);
  const findDropdownItemAtIndex = (index) => findDropdownItems().at(index);

  const createComponent = (props = {}) => {
    wrapper = shallowMount(CodeDropdownIdeItem, {
      propsData: {
        ...props,
      },
    });
  };

  describe('when a list of items is passed in', () => {
    const mockButtonGroupItems = {
      text: 'Test Group',
      items: [
        { text: 'Option 1', href: '/link1' },
        { text: 'Option 2', href: '/link2' },
      ],
    };

    beforeEach(() => {
      createComponent({ ideItem: mockButtonGroupItems });
    });

    it('renders correct number of buttons in a button group', () => {
      expect(findButtonGroup().exists()).toBe(true);
      expect(findAllGlButtons()).toHaveLength(2);
    });

    it('sets correct button properties', () => {
      mockButtonGroupItems.items.forEach((item, index) => {
        const button = findGlButtonAtIndex(index);
        expect(button.attributes('href')).toBe(item.href);
        expect(button.text()).toBe(item.text);
      });
    });

    it('closes the dropdown on click', () => {
      findGlButtonAtIndex(0).vm.$emit('click');
      expect(wrapper.emitted('close-dropdown')).toStrictEqual([[]]);
    });
  });

  describe('when href is passed in', () => {
    const mockButtonItem = {
      type: 'button',
      text: 'button 1',
      href: '/link 1',
    };

    beforeEach(() => {
      createComponent({ ideItem: mockButtonItem });
    });

    it('renders correct number of dropdown item', () => {
      expect(findDropdownItems()).toHaveLength(1);
    });

    it('sets correct properties', () => {
      const dropdownItem = findDropdownItemAtIndex(0);
      expect(dropdownItem.props('item')).toStrictEqual(mockButtonItem);
    });

    it('closes the dropdown on click', () => {
      findDropdownItemAtIndex(0).vm.$emit('action');
      expect(wrapper.emitted('close-dropdown')).toStrictEqual([[]]);
    });
  });
});
