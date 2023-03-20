import { nextTick } from 'vue';
import { GlSkeletonLoader, GlAlert } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import Skeleton from '~/observability/components/skeleton/index.vue';
import DashboardsSkeleton from '~/observability/components/skeleton/dashboards.vue';
import ExploreSkeleton from '~/observability/components/skeleton/explore.vue';
import ManageSkeleton from '~/observability/components/skeleton/manage.vue';
import EmbedSkeleton from '~/observability/components/skeleton/embed.vue';

import {
  SKELETON_VARIANTS_BY_ROUTE,
  DEFAULT_TIMERS,
  SKELETON_VARIANT_EMBED,
} from '~/observability/constants';

describe('Skeleton component', () => {
  let wrapper;

  const SKELETON_VARIANTS = Object.values(SKELETON_VARIANTS_BY_ROUTE);

  const findContentWrapper = () => wrapper.findByTestId('observability-wrapper');

  const findExploreSkeleton = () => wrapper.findComponent(ExploreSkeleton);

  const findDashboardsSkeleton = () => wrapper.findComponent(DashboardsSkeleton);

  const findManageSkeleton = () => wrapper.findComponent(ManageSkeleton);

  const findEmbedSkeleton = () => wrapper.findComponent(EmbedSkeleton);

  const findAlert = () => wrapper.findComponent(GlAlert);

  const mountComponent = ({ ...props } = {}) => {
    wrapper = shallowMountExtended(Skeleton, {
      propsData: props,
    });
  };

  describe('on mount', () => {
    beforeEach(() => {
      mountComponent({ variant: 'explore' });
    });

    describe('loading timers', () => {
      it('show Skeleton if content is not loaded within CONTENT_WAIT_MS', async () => {
        expect(findExploreSkeleton().exists()).toBe(false);
        expect(findContentWrapper().isVisible()).toBe(false);

        jest.advanceTimersByTime(DEFAULT_TIMERS.CONTENT_WAIT_MS);

        await nextTick();

        expect(findExploreSkeleton().exists()).toBe(true);
        expect(findContentWrapper().isVisible()).toBe(false);
      });

      it('does not show the skeleton if content has loaded within CONTENT_WAIT_MS', async () => {
        expect(findExploreSkeleton().exists()).toBe(false);
        expect(findContentWrapper().isVisible()).toBe(false);

        wrapper.vm.onContentLoaded();

        await nextTick();

        expect(findContentWrapper().isVisible()).toBe(true);
        expect(findExploreSkeleton().exists()).toBe(false);

        jest.advanceTimersByTime(DEFAULT_TIMERS.CONTENT_WAIT_MS);

        await nextTick();

        expect(findContentWrapper().isVisible()).toBe(true);
        expect(findExploreSkeleton().exists()).toBe(false);
      });
    });

    describe('error timeout', () => {
      it('shows the error dialog if content has not loaded within TIMEOUT_MS', async () => {
        expect(findAlert().exists()).toBe(false);
        jest.advanceTimersByTime(DEFAULT_TIMERS.TIMEOUT_MS);

        await nextTick();

        expect(findAlert().exists()).toBe(true);
        expect(findContentWrapper().isVisible()).toBe(false);
      });

      it('does not show the error dialog if content has loaded within TIMEOUT_MS', async () => {
        wrapper.vm.onContentLoaded();
        jest.advanceTimersByTime(DEFAULT_TIMERS.TIMEOUT_MS);

        await nextTick();

        expect(findAlert().exists()).toBe(false);
        expect(findContentWrapper().isVisible()).toBe(true);
      });
    });
  });

  describe('skeleton variant', () => {
    it.each`
      skeletonType    | condition                                         | variant
      ${'dashboards'} | ${'variant is dashboards'}                        | ${SKELETON_VARIANTS[0]}
      ${'explore'}    | ${'variant is explore'}                           | ${SKELETON_VARIANTS[1]}
      ${'manage'}     | ${'variant is manage'}                            | ${SKELETON_VARIANTS[2]}
      ${'embed'}      | ${'variant is embed'}                             | ${SKELETON_VARIANT_EMBED}
      ${'default'}    | ${'variant is not manage, dashboards or explore'} | ${'unknown'}
    `('should render $skeletonType skeleton if $condition', async ({ skeletonType, variant }) => {
      mountComponent({ variant });
      jest.advanceTimersByTime(DEFAULT_TIMERS.CONTENT_WAIT_MS);
      await nextTick();
      const showsDefaultSkeleton = ![...SKELETON_VARIANTS, SKELETON_VARIANT_EMBED].includes(
        variant,
      );

      expect(findDashboardsSkeleton().exists()).toBe(skeletonType === SKELETON_VARIANTS[0]);
      expect(findExploreSkeleton().exists()).toBe(skeletonType === SKELETON_VARIANTS[1]);
      expect(findManageSkeleton().exists()).toBe(skeletonType === SKELETON_VARIANTS[2]);
      expect(findEmbedSkeleton().exists()).toBe(skeletonType === SKELETON_VARIANT_EMBED);

      expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(showsDefaultSkeleton);
    });
  });

  describe('on destroy', () => {
    it('should clear init timer and timeout timer', () => {
      jest.spyOn(global, 'clearTimeout');
      mountComponent();
      wrapper.destroy();
      expect(clearTimeout).toHaveBeenCalledTimes(2);
      expect(clearTimeout.mock.calls).toEqual([
        [wrapper.vm.loadingTimeout], // First call
        [wrapper.vm.errorTimeout], // Second call
      ]);
    });
  });
});
