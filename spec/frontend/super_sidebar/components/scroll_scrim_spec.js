import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ScrollScrim from '~/super_sidebar/components/scroll_scrim.vue';
import { useMockIntersectionObserver } from 'helpers/mock_dom_observer';

describe('ScrollScrim', () => {
  let wrapper;
  const { trigger: triggerIntersection } = useMockIntersectionObserver();

  const createWrapper = () => {
    wrapper = shallowMountExtended(ScrollScrim, {});
  };

  beforeEach(() => {
    createWrapper();
  });

  const findTopBoundary = () => wrapper.vm.$refs['top-boundary'];
  const findBottomBoundary = () => wrapper.vm.$refs['bottom-boundary'];

  describe('top scrim', () => {
    describe('when top boundary is visible', () => {
      it('does not show', async () => {
        triggerIntersection(findTopBoundary(), { entry: { isIntersecting: true } });
        await nextTick();

        expect(wrapper.classes()).not.toContain('top-scrim-visible');
      });
    });

    describe('when top boundary is not visible', () => {
      it('does show', async () => {
        triggerIntersection(findTopBoundary(), { entry: { isIntersecting: false } });
        await nextTick();

        expect(wrapper.classes()).toContain('top-scrim-visible');
      });
    });
  });

  describe('bottom scrim', () => {
    describe('when bottom boundary is visible', () => {
      it('does not show', async () => {
        triggerIntersection(findBottomBoundary(), { entry: { isIntersecting: true } });
        await nextTick();

        expect(wrapper.classes()).not.toContain('bottom-scrim-visible');
      });
    });

    describe('when bottom boundary is not visible', () => {
      it('does show', async () => {
        triggerIntersection(findBottomBoundary(), { entry: { isIntersecting: false } });
        await nextTick();

        expect(wrapper.classes()).toContain('bottom-scrim-visible');
      });
    });
  });
});
