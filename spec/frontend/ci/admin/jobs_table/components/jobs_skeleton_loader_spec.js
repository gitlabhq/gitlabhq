import { GlSkeletonLoader } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import JobsSkeletonLoader from '~/ci/admin/jobs_table/components/jobs_skeleton_loader.vue';

describe('jobs_skeleton_loader.vue', () => {
  let wrapper;

  const findGlSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);

  const WIDTH = '1248';
  const HEIGHT = '73';

  beforeEach(() => {
    wrapper = shallowMount(JobsSkeletonLoader);
  });

  it('renders a GlSkeletonLoader', () => {
    expect(findGlSkeletonLoader().exists()).toBe(true);
  });

  it('has correct width', () => {
    expect(findGlSkeletonLoader().attributes('width')).toBe(WIDTH);
  });

  it('has correct height', () => {
    expect(findGlSkeletonLoader().attributes('height')).toBe(HEIGHT);
  });
});
