import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ItemStats from '~/groups/components/item_stats.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

import { mockParentGroupItem, ITEM_TYPE } from '../mock_data';

describe('ItemStats', () => {
  let wrapper;

  const defaultProps = {
    item: mockParentGroupItem,
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(ItemStats, {
      propsData: { ...defaultProps, ...props },
    });
  };

  it('renders component container element correctly', () => {
    createComponent();

    expect(wrapper.classes()).toContain('stats');
  });

  it('renders last updated information for project item correctly', () => {
    const lastActivityAt = '2017-04-09T18:40:39.101Z';

    const item = {
      ...mockParentGroupItem,
      type: ITEM_TYPE.PROJECT,
      lastActivityAt,
    };

    createComponent({ item });

    expect(wrapper.findComponent(TimeAgoTooltip).props('time')).toBe(lastActivityAt);
  });

  describe.each`
    count        | expectedStat
    ${undefined} | ${'0'}
    ${null}      | ${'0'}
    ${4500}      | ${'4.5k'}
  `('when `starCount` is $count', ({ count, expectedStat }) => {
    it(`renders star count as ${expectedStat}`, () => {
      const item = {
        ...mockParentGroupItem,
        type: ITEM_TYPE.PROJECT,
        starCount: count,
      };

      createComponent({ item });

      expect(wrapper.findByTestId('star-count').props('value')).toBe(expectedStat);
    });
  });

  describe('when subgroup count is undefined', () => {
    it('does not render subgroup count', () => {
      const item = {
        ...mockParentGroupItem,
        subgroupCount: undefined,
      };

      createComponent({ item });

      expect(wrapper.findByTestId('subgroup-count').exists()).toBe(false);
    });
  });

  describe('when subgroup count is 4500', () => {
    it('renders subgroup count as 4.5k', () => {
      const item = {
        ...mockParentGroupItem,
        subgroupCount: 4500,
      };

      createComponent({ item });

      expect(wrapper.findByTestId('subgroup-count').props('value')).toBe('4.5k');
    });
  });

  describe('when project count is undefined', () => {
    it('does not render project count', () => {
      const item = {
        ...mockParentGroupItem,
        projectCount: undefined,
      };

      createComponent({ item });

      expect(wrapper.findByTestId('project-count').exists()).toBe(false);
    });
  });

  describe('when project count is 4500', () => {
    it('renders project count as 4.5k', () => {
      const item = {
        ...mockParentGroupItem,
        projectCount: 4500,
      };

      createComponent({ item });

      expect(wrapper.findByTestId('project-count').props('value')).toBe('4.5k');
    });
  });
});
