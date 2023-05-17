import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ItemStats from '~/groups/components/item_stats.vue';
import ItemStatsValue from '~/groups/components/item_stats_value.vue';

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

  const findItemStatsValue = () => wrapper.findComponent(ItemStatsValue);

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
        lastActivityAt: '2017-04-09T18:40:39.101Z',
      };

      createComponent({ item });

      expect(findItemStatsValue().exists()).toBe(true);
      expect(findItemStatsValue().props('cssClass')).toBe('project-stars');
      expect(wrapper.find('.last-updated').exists()).toBe(true);
    });

    describe('group specific rendering', () => {
      describe.each`
        provided | state                 | data
        ${true}  | ${'displays'}         | ${null}
        ${false} | ${'does not display'} | ${{ subgroupCount: undefined, projectCount: undefined }}
      `('when provided = $provided', ({ provided, state, data }) => {
        beforeEach(() => {
          const item = {
            ...mockParentGroupItem,
            ...data,
            type: ITEM_TYPE.GROUP,
          };

          createComponent({ item });
        });

        it.each`
          entity         | testId
          ${'subgroups'} | ${'subgroups-count'}
          ${'projects'}  | ${'projects-count'}
        `(`${state} $entity count`, ({ testId }) => {
          expect(wrapper.findByTestId(testId).exists()).toBe(provided);
        });
      });
    });
  });
});
