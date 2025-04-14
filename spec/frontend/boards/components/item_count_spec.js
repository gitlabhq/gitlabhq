import { GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import IssueCount from '~/boards/components/item_count.vue';

describe('IssueCount', () => {
  let wrapper;
  let maxCount;
  let currentCount;

  const createComponent = (props) => {
    wrapper = shallowMount(IssueCount, { propsData: props });
  };

  const findGlSprintf = () => wrapper.findComponent(GlSprintf);

  afterEach(() => {
    maxCount = 0;
    currentCount = 0;
  });

  describe('when maxCount is zero', () => {
    beforeEach(() => {
      currentCount = 3;

      createComponent({ maxCount: 0, currentCount });
    });

    it('contains currentCount in the template', () => {
      expect(wrapper.find('[data-testid="board-items-count"]').text()).toEqual(
        String(currentCount),
      );
    });

    it('does not contains maxCount in the template', () => {
      expect(wrapper.find('.max-issue-size').exists()).toBe(false);
    });
  });

  describe('when maxCount is greater than zero', () => {
    beforeEach(() => {
      maxCount = 2;
      currentCount = 1;

      createComponent({ maxCount, currentCount });
    });

    it('contains issueSize in the template', () => {
      expect(wrapper.find('[data-testid="board-items-count"]').text()).toEqual(
        String(currentCount),
      );
    });

    it('contains maxCount in the template', () => {
      expect(findGlSprintf().attributes('message')).toContain(`/ %{maxCount}`);
    });

    it('does not have red text when issueSize is less than maxCount', () => {
      expect(wrapper.classes('.gl-text-red-700')).toBe(false);
    });
  });

  describe('when issueSize is greater than maxCount', () => {
    beforeEach(() => {
      currentCount = 3;
      maxCount = 2;

      createComponent({ maxCount, currentCount });
    });

    it('contains issueSize in the template', () => {
      expect(wrapper.find('[data-testid="board-items-count"]').text()).toEqual(
        String(currentCount),
      );
    });

    it('contains maxCount in the template', () => {
      expect(findGlSprintf().attributes('message')).toContain(`/ %{maxCount}`);
    });

    it('has red text', () => {
      expect(wrapper.find('.gl-text-red-700').text()).toEqual(String(currentCount));
    });
  });
});
