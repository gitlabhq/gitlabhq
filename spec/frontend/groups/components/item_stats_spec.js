import { shallowMount } from '@vue/test-utils';
import ItemStats from '~/groups/components/item_stats.vue';
import ItemStatsValue from '~/groups/components/item_stats_value.vue';

import { mockParentGroupItem, ITEM_TYPE } from '../mock_data';

describe('ItemStats', () => {
  let wrapper;

  const defaultProps = {
    item: mockParentGroupItem,
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(ItemStats, {
      propsData: { ...defaultProps, ...props },
    });
  };

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  const findItemStatsValue = () => wrapper.find(ItemStatsValue);

  describe('template', () => {
    it('renders component container element correctly', () => {
      createComponent();

      expect(wrapper.classes()).toContain('stats');
    });

    it('renders start count and last updated information for project item correctly', () => {
      const item = {
        ...mockParentGroupItem,
        type: ITEM_TYPE.PROJECT,
        starCount: 4,
      };

      createComponent({ item });

      expect(findItemStatsValue().exists()).toBe(true);
      expect(findItemStatsValue().props('cssClass')).toBe('project-stars');
      expect(wrapper.contains('.last-updated')).toBe(true);
    });
  });
});
