import { GlDisclosureDropdown, GlDisclosureDropdownItem } from '@gitlab/ui';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemLinksMenu from '~/work_items/components/shared/work_item_links_menu.vue';

describe('WorkItemLinksMenu', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(WorkItemLinksMenu);
  };

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findRemoveDropdownItem = () => wrapper.findComponent(GlDisclosureDropdownItem);

  beforeEach(() => {
    createComponent();
  });

  it('renders dropdown and dropdown items', () => {
    expect(findDropdown().exists()).toBe(true);
    expect(findRemoveDropdownItem().exists()).toBe(true);
  });

  it('emits removeChild event on click Remove', () => {
    findRemoveDropdownItem().vm.$emit('action');

    expect(wrapper.emitted('removeChild')).toHaveLength(1);
  });
});
