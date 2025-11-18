import { shallowMount } from '@vue/test-utils';
import { GlDisclosureDropdownItem } from '@gitlab/ui';
import DiffFileOptionsMenuItem from '~/rapid_diffs/app/components/diff_file_options_menu_item.vue';

describe('DiffFileOptionsMenuItem', () => {
  let wrapper;

  const createComponent = (item = {}) => {
    wrapper = shallowMount(DiffFileOptionsMenuItem, {
      propsData: { item },
    });
  };

  const findDropdownItem = () => wrapper.findComponent(GlDisclosureDropdownItem);

  it('passes the item prop to GlDisclosureDropdownItem', () => {
    const item = { text: 'Test item' };
    createComponent(item);

    expect(findDropdownItem().props('item')).toBe(item);
  });

  it('renders HTML content in the list-item slot', () => {
    const item = { text: 'View file at <code>abc1234</code>' };
    createComponent(item);

    const slotContent = findDropdownItem().find('span');

    expect(slotContent.exists()).toBe(true);
    expect(slotContent.html()).toContain('<code>abc1234</code>');
  });
});
