import { nextTick } from 'vue';
import { GlSkeletonLoader, GlAlert, GlLoadingIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import Skeleton from '~/observability/components/skeleton/index.vue';

import { DEFAULT_TIMERS } from '~/observability/constants';

describe('Skeleton component', () => {
  let wrapper;

  const findSpinner = () => wrapper.findComponent(GlLoadingIcon);

  const findContentWrapper = () => wrapper.findByTestId('content-wrapper');

  const findAlert = () => wrapper.findComponent(GlAlert);

  const mountComponent = ({ ...props } = {}) => {
    wrapper = shallowMountExtended(Skeleton, {
      propsData: props,
    });
  };

  describe('on mount', () => {
    beforeEach(() => {
      mountComponent({ variant: 'spinner' });
    });

    describe('showing content', () => {
      it('shows the skeleton if content is not loaded within CONTENT_WAIT_MS', async () => {
        expect(findSpinner().exists()).toBe(false);
        expect(findContentWrapper().exists()).toBe(false);

        jest.advanceTimersByTime(DEFAULT_TIMERS.CONTENT_WAIT_MS);

        await nextTick();

        expect(findSpinner().exists()).toBe(true);
        expect(findContentWrapper().exists()).toBe(false);
      });

      it('does not show the skeleton if content loads within CONTENT_WAIT_MS', async () => {
        expect(findSpinner().exists()).toBe(false);
        expect(findContentWrapper().exists()).toBe(false);

        wrapper.vm.onContentLoaded();

        await nextTick();

        expect(findContentWrapper().exists()).toBe(true);
        expect(findSpinner().exists()).toBe(false);

        jest.advanceTimersByTime(DEFAULT_TIMERS.CONTENT_WAIT_MS);

        await nextTick();

        expect(findContentWrapper().exists()).toBe(true);
        expect(findSpinner().exists()).toBe(false);
      });

      it('hides the skeleton after content loads', async () => {
        jest.advanceTimersByTime(DEFAULT_TIMERS.CONTENT_WAIT_MS);

        await nextTick();

        expect(findSpinner().exists()).toBe(true);
        expect(findContentWrapper().exists()).toBe(false);

        wrapper.vm.onContentLoaded();

        await nextTick();

        expect(findContentWrapper().exists()).toBe(true);
        expect(findSpinner().exists()).toBe(false);
      });
    });

    describe('error handling', () => {
      it('shows the error dialog if content has not loaded within TIMEOUT_MS', async () => {
        expect(findAlert().exists()).toBe(false);
        jest.advanceTimersByTime(DEFAULT_TIMERS.TIMEOUT_MS);

        await nextTick();

        expect(findAlert().exists()).toBe(true);
        expect(findContentWrapper().exists()).toBe(false);
      });

      it('shows the error dialog if content fails to load', async () => {
        expect(findAlert().exists()).toBe(false);

        wrapper.vm.onError();

        await nextTick();

        expect(findAlert().exists()).toBe(true);
        expect(findContentWrapper().exists()).toBe(false);
      });

      it('does not show the error dialog if content has loaded within TIMEOUT_MS', async () => {
        wrapper.vm.onContentLoaded();
        jest.advanceTimersByTime(DEFAULT_TIMERS.TIMEOUT_MS);

        await nextTick();

        expect(findAlert().exists()).toBe(false);
        expect(findContentWrapper().exists()).toBe(true);
      });
    });
  });

  describe('skeleton variant', () => {
    it('shows only the spinner variant when variant is spinner', async () => {
      mountComponent({ variant: 'spinner' });
      jest.advanceTimersByTime(DEFAULT_TIMERS.CONTENT_WAIT_MS);
      await nextTick();

      expect(findSpinner().exists()).toBe(true);
      expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(false);
    });

    it('shows only the default variant when variant is not spinner', async () => {
      mountComponent({ variant: 'unknown' });
      jest.advanceTimersByTime(DEFAULT_TIMERS.CONTENT_WAIT_MS);
      await nextTick();

      expect(findSpinner().exists()).toBe(false);
      expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(true);
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
