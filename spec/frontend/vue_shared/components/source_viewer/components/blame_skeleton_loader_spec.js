import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BlameSkeletonLoader from '~/vue_shared/components/source_viewer/components/blame_skeleton_loader.vue';

describe('BlameSkeletonLoader component', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(BlameSkeletonLoader);
  };

  const findSkeletonLoader = () => wrapper.findByTestId('blame-skeleton-loader');
  const findSkeletonAvatar = () => wrapper.findByTestId('blame-skeleton-avatar');
  const findSkeletonLines = () => wrapper.findAllByTestId('blame-skeleton-line');

  it('renders skeleton loader elements', () => {
    createComponent();

    expect(findSkeletonLoader().exists()).toBe(true);
    expect(findSkeletonAvatar().exists()).toBe(true);
    expect(findSkeletonLines()).toHaveLength(3);
  });

  it('has accessible loading state', () => {
    createComponent();

    expect(findSkeletonLoader().attributes()).toMatchObject({
      role: 'status',
      'aria-busy': 'true',
      'aria-label': 'Loading blame information',
    });
  });
});
