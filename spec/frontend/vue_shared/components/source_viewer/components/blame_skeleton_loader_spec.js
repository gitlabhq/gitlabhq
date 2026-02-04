import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BlameSkeletonLoader from '~/vue_shared/components/source_viewer/components/blame_skeleton_loader.vue';

describe('BlameSkeletonLoader component', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(BlameSkeletonLoader);
  };

  const findSkeletonLoader = () => wrapper.findByTestId('blame-skeleton-loader');
  const findSkeletonBar = () => wrapper.findByTestId('blame-skeleton-bar');
  const findSkeletonDate = () => wrapper.findByTestId('blame-skeleton-date');
  const findSkeletonAvatar = () => wrapper.findByTestId('blame-skeleton-avatar');
  const findSkeletonTitle = () => wrapper.findByTestId('blame-skeleton-title');

  beforeEach(() => createComponent());

  it('renders skeleton loader elements', () => {
    expect(findSkeletonLoader().exists()).toBe(true);
    expect(findSkeletonBar().exists()).toBe(true);
    expect(findSkeletonDate().exists()).toBe(true);
    expect(findSkeletonAvatar().exists()).toBe(true);
    expect(findSkeletonTitle().exists()).toBe(true);
  });

  it('has accessible loading state', () => {
    expect(findSkeletonLoader().attributes()).toMatchObject({
      role: 'status',
      'aria-busy': 'true',
      'aria-label': 'Loading blame information',
    });
  });
});
