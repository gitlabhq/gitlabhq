import { GlDropdown, GlDropdownItem } from '@gitlab/ui';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemLinksMenu from '~/work_items/components/work_item_links/work_item_links_menu.vue';

describe('WorkItemLinksMenu', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(WorkItemLinksMenu);
  };

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findRemoveDropdownItem = () => wrapper.findComponent(GlDropdownItem);

  beforeEach(() => {
    createComponent();
  });

  it('renders dropdown and dropdown items', () => {
    expect(findDropdown().exists()).toBe(true);
    expect(findRemoveDropdownItem().exists()).toBe(true);
  });

  it('emits removeChild event on click Remove', () => {
    findRemoveDropdownItem().vm.$emit('click');

    expect(wrapper.emitted('removeChild')).toHaveLength(1);
  });
});
