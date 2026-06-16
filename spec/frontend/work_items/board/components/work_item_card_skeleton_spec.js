import { GlSkeletonLoader } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemCardSkeleton from '~/work_items/board/components/work_item_card_skeleton.vue';

describe('WorkItemCardSkeleton', () => {
  let wrapper;

  const findCard = () => wrapper.findByTestId('work-item-card-skeleton');
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);

  beforeEach(() => {
    wrapper = shallowMountExtended(WorkItemCardSkeleton);
  });

  it('renders a ghost card containing a skeleton loader', () => {
    expect(findCard().exists()).toBe(true);
    expect(findSkeletonLoader().exists()).toBe(true);
  });
});
