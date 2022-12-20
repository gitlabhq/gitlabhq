import { GlSkeletonLoader } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import ObservabilitySkeleton from '~/observability/components/skeleton/index.vue';
import DashboardsSkeleton from '~/observability/components/skeleton/dashboards.vue';
import ExploreSkeleton from '~/observability/components/skeleton/explore.vue';
import ManageSkeleton from '~/observability/components/skeleton/manage.vue';

import { SKELETON_VARIANT } from '~/observability/constants';

describe('ObservabilitySkeleton component', () => {
  let wrapper;

  const mountComponent = ({ ...props } = {}) => {
    wrapper = shallowMountExtended(ObservabilitySkeleton, {
      propsData: props,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('on mount', () => {
    beforeEach(() => {
      jest.spyOn(global, 'setTimeout');
      mountComponent();
    });

    it('should call setTimeout on mount and show ObservabilitySkeleton if Observability UI is not loaded yet', () => {
      jest.runAllTimers();

      expect(setTimeout).toHaveBeenCalledWith(expect.any(Function), 500);
      expect(wrapper.vm.loading).toBe(true);
      expect(wrapper.vm.timerId).not.toBeNull();
    });

    it('should call setTimeout on mount and dont show ObservabilitySkeleton if Observability UI is loaded', () => {
      wrapper.vm.loading = false;
      jest.runAllTimers();

      expect(setTimeout).toHaveBeenCalledWith(expect.any(Function), 500);
      expect(wrapper.vm.loading).toBe(false);
      expect(wrapper.vm.timerId).not.toBeNull();
    });
  });

  describe('handleSkeleton', () => {
    it('will not show the skeleton if Observability UI is loaded before', () => {
      jest.spyOn(global, 'clearTimeout');
      mountComponent();
      wrapper.vm.handleSkeleton();
      expect(clearTimeout).toHaveBeenCalledWith(wrapper.vm.timerId);
    });

    it('will hide skeleton gracefully after 400ms if skeleton was present on screen before Observability UI', () => {
      jest.spyOn(global, 'setTimeout');
      mountComponent();
      jest.runAllTimers();
      wrapper.vm.handleSkeleton();
      jest.runAllTimers();

      expect(setTimeout).toHaveBeenCalledWith(wrapper.vm.hideSkeleton, 400);
      expect(wrapper.vm.loading).toBe(false);
    });
  });

  describe('skeleton variant', () => {
    it.each`
      skeletonType    | condition                                         | variant
      ${'dashboards'} | ${'variant is dashboards'}                        | ${SKELETON_VARIANT.DASHBOARDS}
      ${'explore'}    | ${'variant is explore'}                           | ${SKELETON_VARIANT.EXPLORE}
      ${'manage'}     | ${'variant is manage'}                            | ${SKELETON_VARIANT.MANAGE}
      ${'default'}    | ${'variant is not manage, dashboards or explore'} | ${'unknown'}
    `('should render $skeletonType skeleton if $condition', async ({ skeletonType, variant }) => {
      mountComponent({ variant });
      const showsDefaultSkeleton = ![
        SKELETON_VARIANT.DASHBOARDS,
        SKELETON_VARIANT.EXPLORE,
        SKELETON_VARIANT.MANAGE,
      ].includes(variant);
      expect(wrapper.findComponent(DashboardsSkeleton).exists()).toBe(
        skeletonType === SKELETON_VARIANT.DASHBOARDS,
      );
      expect(wrapper.findComponent(ExploreSkeleton).exists()).toBe(
        skeletonType === SKELETON_VARIANT.EXPLORE,
      );
      expect(wrapper.findComponent(ManageSkeleton).exists()).toBe(
        skeletonType === SKELETON_VARIANT.MANAGE,
      );

      expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(showsDefaultSkeleton);
    });
  });
});
