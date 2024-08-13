import { GlIcon, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import DisclosureHierarchyItem from '~/work_items/components/work_item_ancestors/disclosure_hierarchy_item.vue';
import {
  mockDisclosureHierarchyItems,
  mockDisclosureHierarchyItemsWithNoPermission,
} from './mock_data';

describe('DisclosurePathItem', () => {
  let wrapper;

  const findIcon = () => wrapper.findComponent(GlIcon);
  const findAncestorLink = () => wrapper.findComponent(GlLink);

  const createComponent = (props = {}, options = {}) => {
    return shallowMount(DisclosureHierarchyItem, {
      propsData: {
        item: mockDisclosureHierarchyItems[0],
        ...props,
      },
      ...options,
    });
  };

  beforeEach(() => {
    wrapper = createComponent();
  });

  describe('renders the item', () => {
    it('renders the inline icon', () => {
      expect(findIcon().exists()).toBe(true);
      expect(findIcon().props('name')).toBe(mockDisclosureHierarchyItems[0].icon);
    });

    it('renders the link', () => {
      expect(findAncestorLink().exists()).toBe(true);
      expect(findAncestorLink().text()).toBe(mockDisclosureHierarchyItems[0].title);
      expect(findAncestorLink().classes('gl-cursor-help')).toBe(false);
    });

    it('renders the link with help cursor when item ancestors are inaccesible', () => {
      wrapper = createComponent({ item: mockDisclosureHierarchyItemsWithNoPermission });

      expect(findAncestorLink().classes('gl-cursor-help')).toBe(true);
      expect(findAncestorLink().text()).toBe(mockDisclosureHierarchyItemsWithNoPermission.title);
    });
  });

  describe('item slot', () => {
    beforeEach(() => {
      wrapper = createComponent(null, {
        scopedSlots: {
          default: `
            <div
              data-testid="item-slot-content">
              {{ props.item.title }}
            </div>
          `,
        },
      });
    });

    it('contains all elements passed into the additional slot', () => {
      const item = wrapper.find('[data-testid="item-slot-content"]');

      expect(item.text()).toBe(mockDisclosureHierarchyItems[0].title);
    });
  });
});
