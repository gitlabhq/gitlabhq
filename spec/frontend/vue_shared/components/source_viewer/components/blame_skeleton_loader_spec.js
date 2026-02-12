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

  it('renders a row for each line in the chunk', () => {
    createComponent({ totalLines: 5 });

    expect(findAllSkeletonBars()).toHaveLength(5);
    expect(findAllSkeletonDates()).toHaveLength(5);
    expect(findAllSkeletonAvatars()).toHaveLength(5);
    expect(findAllSkeletonTitles()).toHaveLength(5);
  });
});
