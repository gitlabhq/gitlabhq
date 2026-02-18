import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BlameSkeletonLoader from '~/vue_shared/components/source_viewer/components/blame_skeleton_loader.vue';

describe('BlameSkeletonLoader component', () => {
  let wrapper;

  const createComponent = (props = { totalLines: 1 }) => {
    wrapper = shallowMountExtended(BlameSkeletonLoader, { propsData: props });
  };

  const findSkeletonLoader = () => wrapper.findByTestId('blame-skeleton-loader');
  const findAllSkeletonBars = () => wrapper.findAllByTestId('blame-skeleton-bar');
  const findAllSkeletonDates = () => wrapper.findAllByTestId('blame-skeleton-date');
  const findAllSkeletonAvatars = () => wrapper.findAllByTestId('blame-skeleton-avatar');
  const findAllSkeletonTitles = () => wrapper.findAllByTestId('blame-skeleton-title');

  beforeEach(() => createComponent());

  it('renders skeleton loader elements', () => {
    expect(findSkeletonLoader().exists()).toBe(true);
    expect(findAllSkeletonBars()).toHaveLength(1);
    expect(findAllSkeletonDates()).toHaveLength(1);
    expect(findAllSkeletonAvatars()).toHaveLength(1);
    expect(findAllSkeletonTitles()).toHaveLength(1);
  });

  it('has accessible loading state', () => {
    expect(findSkeletonLoader().attributes()).toMatchObject({
      role: 'status',
      'aria-busy': 'true',
      'aria-label': 'Loading blame information',
    });
  });

  it('renders a loader every 2nd line by default', () => {
    createComponent({ totalLines: 8 });

    expect(findAllSkeletonBars()).toHaveLength(4);
    expect(findAllSkeletonDates()).toHaveLength(4);
    expect(findAllSkeletonAvatars()).toHaveLength(4);
    expect(findAllSkeletonTitles()).toHaveLength(4);
  });

  it('offsets loader positions using startLine', () => {
    // Without offset: 5 lines with loaders every 2nd line = 3 loaders
    createComponent({ totalLines: 5 });
    expect(findAllSkeletonBars()).toHaveLength(3);

    // With offset: startLine shifts positions, resulting in 2 loaders instead of 3
    createComponent({ totalLines: 5, startLine: 3 });
    expect(findAllSkeletonBars()).toHaveLength(2);
  });
});
