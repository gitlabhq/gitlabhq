import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemRolledUpCount from '~/work_items/components/work_item_links/work_item_rolled_up_count.vue';
import WorkItemRolledUpCountInfo from '~/work_items/components/work_item_links/work_item_rolled_up_count_info.vue';
import { mockRolledUpCountsByType } from 'jest/work_items/mock_data';

describe('Work Item rolled up count', () => {
  let wrapper;

  const createComponent = ({
    infoType = 'badge',
    rolledUpCountsByType = mockRolledUpCountsByType,
    hideCountWhenZero = false,
  } = {}) => {
    wrapper = shallowMountExtended(WorkItemRolledUpCount, {
      propsData: {
        infoType,
        rolledUpCountsByType,
        hideCountWhenZero,
      },
    });
  };

  const findRolledUpCountWrapper = () => wrapper.findByTestId('work-item-rolled-up-count-wrapper');
  const findRolledUpCountBadgeView = () => wrapper.findByTestId('work-item-rolled-up-badge-count');
  const findRolledUpCountDetailedView = () =>
    wrapper.findByTestId('work-item-rolled-up-detailed-count');
  const findBadgePopover = () => wrapper.findByTestId('badge-popover');
  const findDetailedPopover = () => wrapper.findByTestId('detailed-popover');
  const findBadgePopoverWarning = () => wrapper.findByTestId('badge-warning');
  const findBadgePopoverRolledUpCountInfo = () =>
    findBadgePopover().findComponent(WorkItemRolledUpCountInfo);
  const findDetailedPopoverRolledUpCountInfo = () =>
    findDetailedPopover().findComponent(WorkItemRolledUpCountInfo);

  describe('Default', () => {
    it('renders count in `badge` view by default', () => {
      createComponent();

      expect(findRolledUpCountBadgeView().exists()).toBe(true);
      expect(findRolledUpCountDetailedView().exists()).toBe(false);
    });

    it('renders count in `detailed` view when passed appropriate props', () => {
      createComponent({ infoType: 'detailed' });

      expect(findRolledUpCountBadgeView().exists()).toBe(false);
      expect(findRolledUpCountDetailedView().exists()).toBe(true);
    });
  });

  describe('badge view', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the badge popover', () => {
      expect(findBadgePopover().exists()).toBe(true);
    });

    it('renders the rolled up count info component', () => {
      expect(findBadgePopoverRolledUpCountInfo().exists()).toBe(true);
    });

    it('renders the default badge popover warning when rolled up counts exist in header', () => {
      expect(findBadgePopoverWarning().exists()).toBe(true);
      expect(findBadgePopoverWarning().text()).toBe(
        'Roll up totals may reflect child items you don’t have access to.',
      );
    });

    it('when the rolled up count is zero shows a different warning', () => {
      createComponent({ rolledUpCountsByType: [] });

      expect(findBadgePopoverWarning().exists()).toBe(true);
      expect(findBadgePopoverWarning().text()).toBe('No child items are currently assigned.');
    });
  });

  describe('detailed view', () => {
    beforeEach(() => {
      createComponent({ infoType: 'detailed' });
    });

    it('renders the detailed info popover', () => {
      expect(findDetailedPopover().exists()).toBe(true);
    });

    it('renders the rolled up count info component and not badge popover info component', () => {
      expect(findDetailedPopoverRolledUpCountInfo().exists()).toBe(true);
    });
  });

  it.each`
    hideCount | wrapperVisible | shouldRender
    ${false}  | ${true}        | ${'renders'}
    ${true}   | ${false}       | ${'does not render'}
  `(
    '$shouldRender the wrapper when total count is zero and `hideCountWhenZero` is $hideCount',
    ({ hideCount, wrapperVisible }) => {
      createComponent({
        rolledUpCountsByType: [
          {
            countsByState: {
              all: 0,
              closed: 0,
              __typename: 'WorkItemStateCountsType',
            },
            workItemType: {
              id: 'gid://gitlab/WorkItems::Type/5',
              name: 'Task',
              iconName: 'issue-type-task',
              __typename: 'WorkItemType',
            },
            __typename: 'WorkItemTypeCountsByState',
          },
        ],
        hideCountWhenZero: hideCount,
      });
      expect(findRolledUpCountWrapper().exists()).toBe(wrapperVisible);
    },
  );
});
