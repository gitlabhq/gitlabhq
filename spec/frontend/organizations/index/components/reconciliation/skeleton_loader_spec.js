import { GlSkeletonLoader } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import SkeletonLoader from '~/organizations/index/components/reconciliation/skeleton_loader.vue';

describe('ReconciliationSkeletonLoader', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(SkeletonLoader);
  };

  beforeEach(() => {
    createComponent();
  });

  const findGlSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);

  it('renders a GlSkeletonLoader', () => {
    expect(findGlSkeletonLoader().exists()).toBe(true);
  });

  it('has correct width', () => {
    expect(findGlSkeletonLoader().attributes('width')).toBe('600');
  });

  it('has correct height', () => {
    expect(findGlSkeletonLoader().attributes('height')).toBe('310');
  });
});
