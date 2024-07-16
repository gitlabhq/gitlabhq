import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';

import { GlDisclosureDropdown, GlTooltip } from '@gitlab/ui';
import { GlBreakpointInstance } from '@gitlab/ui/dist/utils';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import DisclosureHierarchy from '~/work_items/components/work_item_ancestors//disclosure_hierarchy.vue';
import DisclosureHierarchyItem from '~/work_items/components/work_item_ancestors/disclosure_hierarchy_item.vue';
import { mockDisclosureHierarchyItems } from './mock_data';

describe('DisclosurePath', () => {
  let wrapper;

  const createComponent = (props = {}, options = {}) => {
    return shallowMount(DisclosureHierarchy, {
      propsData: {
        items: mockDisclosureHierarchyItems,
        ...props,
      },
      ...options,
      directives: {
        GlResizeObserver: createMockDirective('gl-resize-observer'),
      },
    });
  };

  const listItems = () => wrapper.findAllComponents(DisclosureHierarchyItem);
  const itemAt = (index) => listItems().at(index);
  const itemTextAt = (index) => itemAt(index).props('item').title;

  beforeEach(() => {
    wrapper = createComponent();
  });

  describe('renders the list of items', () => {
    it('renders the correct number of items', () => {
      expect(listItems().length).toBe(mockDisclosureHierarchyItems.length);
    });

    it('renders the items in the correct order', () => {
      expect(itemTextAt(0)).toContain(mockDisclosureHierarchyItems[0].title);
      expect(itemTextAt(4)).toContain(mockDisclosureHierarchyItems[4].title);
      expect(itemTextAt(9)).toContain(mockDisclosureHierarchyItems[9].title);
    });
  });

  describe('slots', () => {
    beforeEach(() => {
      wrapper = createComponent(null, {
        scopedSlots: {
          default: `
            <div
              :data-itemid="props.itemId"
              data-testid="item-slot-content">
              {{ props.item.title }}
            </div>
          `,
        },
      });
    });

    it('contains all elements passed into the default slot', () => {
      mockDisclosureHierarchyItems.forEach((item, index) => {
        const disclosureItem = wrapper.findAll('[data-testid="item-slot-content"]').at(index);

        expect(disclosureItem.text()).toBe(item.title);
        expect(disclosureItem.attributes('data-itemid')).toContain('disclosure-');
      });
    });
  });

  describe('with ellipsis', () => {
    const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
    const findTooltip = () => wrapper.findComponent(GlTooltip);
    const findTooltipText = () => findTooltip().text();
    const tooltipText = 'Display more items';

    beforeEach(() => {
      wrapper = createComponent({ withEllipsis: true, ellipsisTooltipLabel: tooltipText });
    });

    describe('renders items and dropdown', () => {
      it('renders 2 items', () => {
        expect(listItems().length).toBe(2);
      });

      it('renders first and last items', () => {
        expect(itemTextAt(0)).toContain(mockDisclosureHierarchyItems[0].title);
        expect(itemTextAt(1)).toContain(
          mockDisclosureHierarchyItems[mockDisclosureHierarchyItems.length - 1].title,
        );
      });

      it('renders dropdown with the rest of the items passed down', () => {
        expect(findDropdown().exists()).toBe(true);
        expect(findDropdown().props('items').length).toBe(mockDisclosureHierarchyItems.length - 2);
      });

      it('renders tooltip with text passed as prop', () => {
        expect(findTooltip().exists()).toBe(true);
        expect(findTooltipText()).toBe(tooltipText);
      });
    });

    describe('for mobile', () => {
      beforeEach(async () => {
        wrapper = createComponent({
          withEllipsis: false,
        });

        jest.spyOn(GlBreakpointInstance, 'getBreakpointSize').mockReturnValue('sm');

        window.dispatchEvent(new Event('resize'));
        await nextTick();
        const { value } = getBinding(wrapper.element, 'gl-resize-observer');
        value();
      });

      it('renders 1 item', () => {
        expect(listItems().length).toBe(1);
      });

      it('renders last item', () => {
        expect(itemTextAt(0)).toContain(
          mockDisclosureHierarchyItems[mockDisclosureHierarchyItems.length - 1].title,
        );
      });

      it('renders dropdown with the rest of the items passed down', () => {
        expect(findDropdown().exists()).toBe(true);
        expect(findDropdown().props('items').length).toBe(mockDisclosureHierarchyItems.length - 1);
      });

      describe('when there is one item', () => {
        beforeEach(async () => {
          wrapper = createComponent({
            withEllipsis: false,
            items: [mockDisclosureHierarchyItems[0]],
          });

          jest.spyOn(GlBreakpointInstance, 'getBreakpointSize').mockReturnValue('sm');

          window.dispatchEvent(new Event('resize'));
          await nextTick();
          const { value } = getBinding(wrapper.element, 'gl-resize-observer');
          value();
        });

        it('renders 1 item', () => {
          expect(listItems().length).toBe(1);
        });

        it('does not render dropdown', () => {
          expect(findDropdown().exists()).toBe(false);
        });
      });
    });
  });
});
