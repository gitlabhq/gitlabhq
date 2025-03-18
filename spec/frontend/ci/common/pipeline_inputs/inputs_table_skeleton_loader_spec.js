import { GlSkeletonLoader } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import InputsTableSkeletonLoader from '~/ci/common/pipeline_inputs/inputs_table_skeleton_loader.vue';

describe('InputsTableSkeletonLoader', () => {
  let wrapper;

  const findGlSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findSkeletonRects = () => wrapper.findAll('rect');

  beforeEach(() => {
    wrapper = shallowMount(InputsTableSkeletonLoader);
  });

  it('renders a GlSkeletonLoader', () => {
    expect(findGlSkeletonLoader().exists()).toBe(true);
  });

  it('has correct height', () => {
    expect(findGlSkeletonLoader().attributes('height')).toBe('16');
  });

  it('renders 8 rects (2 rows x 4 columns)', () => {
    expect(findSkeletonRects().length).toBe(8);
  });
});
