import {
  GlDisclosureDropdown,
  GlDisclosureDropdownGroup,
  GlDisclosureDropdownItem,
} from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ActionsButton from '~/vue_shared/components/actions_button.vue';

const TEST_ACTION = {
  key: 'action1',
  text: 'Sample',
  secondaryText: 'Lorem ipsum.',
  href: '/sample',
  attrs: {
    'data-test': '123',
    category: 'secondary',
    href: '/sample',
    variant: 'default',
  },
  handle: jest.fn(),
};
const TEST_ACTION_2 = {
  key: 'action2',
  text: 'Sample 2',
  secondaryText: 'Dolar sit amit.',
  href: '#',
  attrs: { 'data-test': '456' },
  handle: jest.fn(),
};

describe('vue_shared/components/actions_button', () => {
  let wrapper;

  function createComponent(props) {
    wrapper = shallowMountExtended(ActionsButton, {
      propsData: { actions: [TEST_ACTION, TEST_ACTION_2], toggleText: 'Edit', ...props },
      stubs: {
        GlDisclosureDropdownItem,
      },
    });
  }
  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);

  it('dropdown toggle displays provided toggleLabel', () => {
    createComponent();

    expect(findDropdown().props().toggleText).toBe('Edit');
  });

  it('allows customizing variant and category', () => {
    const variant = 'confirm';
    const category = 'secondary';

    createComponent({ variant, category });

    expect(findDropdown().props()).toMatchObject({ category, variant });
  });

  it('displays a single dropdown group', () => {
    createComponent();

    expect(wrapper.findAllComponents(GlDisclosureDropdownGroup)).toHaveLength(1);
  });

  it('create dropdown items for every action', () => {
    createComponent();

    [TEST_ACTION, TEST_ACTION_2].forEach((action, index) => {
      const dropdownItem = wrapper.findAllComponents(GlDisclosureDropdownItem).at(index);

      expect(dropdownItem.props().item).toBe(action);
      expect(dropdownItem.attributes()).toMatchObject(action.attrs);
      expect(dropdownItem.text()).toContain(action.text);
      expect(dropdownItem.text()).toContain(action.secondaryText);
    });
  });

  describe('when clicking a dropdown item', () => {
    it("invokes the action's handle method", () => {
      createComponent();

      [TEST_ACTION, TEST_ACTION_2].forEach((action, index) => {
        const dropdownItem = wrapper.findAllComponents(GlDisclosureDropdownItem).at(index);

        dropdownItem.vm.$emit('action');

        expect(action.handle).toHaveBeenCalled();
      });
    });
  });
});
