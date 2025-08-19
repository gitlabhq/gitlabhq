import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import LoadingStateListItem from '~/vue_shared/components/resource_lists/loading_state_list_item.vue';

describe('LoadingStateListItem', () => {
  let wrapper;

  const createWrapper = (props = {}) => {
    wrapper = shallowMountExtended(LoadingStateListItem, {
      propsData: props,
    });
  };

  const findLeftSkeleton = () => wrapper.findByTestId('loading-state-list-item-left-skeleton');
  const findRightSkeleton = () => wrapper.findByTestId('loading-state-list-item-right-skeleton');

  describe('when mounted', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('adds CSS classes to the right skeleton', () => {
      expect(findRightSkeleton().html()).toContain('gl-hidden sm:gl-block');
    });
  });

  describe('when no attributes are provided', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders left skeleton loader with default lines count', () => {
      const leftSkeleton = findLeftSkeleton();

      expect(leftSkeleton.exists()).toBe(true);
      expect(leftSkeleton.attributes('lines')).toBe('2');
    });

    it('renders right skeleton loader with default lines count and properties', () => {
      const rightSkeleton = findRightSkeleton();

      expect(rightSkeleton.exists()).toBe(true);
      expect(rightSkeleton.attributes('lines')).toBe('2');
    });
  });

  describe('when attributes are provided', () => {
    const leftLinesCount = 3;
    const rightLinesCount = 4;

    beforeEach(() => {
      createWrapper({
        leftLinesCount,
        rightLinesCount,
      });
    });

    it('renders left skeleton loader with custom lines count', () => {
      const leftSkeleton = findLeftSkeleton();

      expect(leftSkeleton.exists()).toBe(true);
      expect(leftSkeleton.attributes('lines')).toBe(`${leftLinesCount}`);
    });

    it('renders right skeleton loader with custom lines count', () => {
      const rightSkeleton = findRightSkeleton();

      expect(rightSkeleton.exists()).toBe(true);
      expect(rightSkeleton.attributes('lines')).toBe(`${rightLinesCount}`);
    });
  });

  describe('when rightLinesCount is zero', () => {
    beforeEach(() => {
      createWrapper({
        rightLinesCount: 0,
      });
    });

    it('does not render right skeleton loader with custom lines count', () => {
      expect(findRightSkeleton().exists()).toBe(false);
    });
  });
});
