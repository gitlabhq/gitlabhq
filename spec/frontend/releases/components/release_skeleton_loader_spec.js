import { mount } from '@vue/test-utils';
import { GlSkeletonLoader } from '@gitlab/ui';
import ReleaseSkeletonLoader from '~/releases/components/release_skeleton_loader.vue';

describe('release_skeleton_loader.vue', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = mount(ReleaseSkeletonLoader);
  });

  it('renders a GlSkeletonLoader', () => {
    expect(wrapper.find(GlSkeletonLoader).exists()).toBe(true);
  });
});
