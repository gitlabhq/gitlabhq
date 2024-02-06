import { shallowMount } from '@vue/test-utils';
import IssueCount from '~/boards/components/item_count.vue';

describe('IssueCount', () => {
  let wrapper;
  let maxIssueCount;
  let itemsSize;

  const createComponent = (props) => {
    wrapper = shallowMount(IssueCount, { propsData: props });
  };

  afterEach(() => {
    maxIssueCount = 0;
    itemsSize = 0;
  });

  describe('when maxIssueCount is zero', () => {
    beforeEach(() => {
      itemsSize = 3;

      createComponent({ maxIssueCount: 0, itemsSize });
    });

    it('contains issueSize in the template', () => {
      expect(wrapper.find('[data-testid="board-items-count"]').text()).toEqual(String(itemsSize));
    });

    it('does not contains maxIssueCount in the template', () => {
      expect(wrapper.find('.max-issue-size').exists()).toBe(false);
    });
  });

  describe('when maxIssueCount is greater than zero', () => {
    beforeEach(() => {
      maxIssueCount = 2;
      itemsSize = 1;

      createComponent({ maxIssueCount, itemsSize });
    });

    it('contains issueSize in the template', () => {
      expect(wrapper.find('[data-testid="board-items-count"]').text()).toEqual(String(itemsSize));
    });

    it('contains maxIssueCount in the template', () => {
      expect(wrapper.find('.max-issue-size').text()).toContain(String(maxIssueCount));
    });

    it('does not have red text when issueSize is less than maxIssueCount', () => {
      expect(wrapper.classes('.gl-text-red-700')).toBe(false);
    });
  });

  describe('when issueSize is greater than maxIssueCount', () => {
    beforeEach(() => {
      itemsSize = 3;
      maxIssueCount = 2;

      createComponent({ maxIssueCount, itemsSize });
    });

    it('contains issueSize in the template', () => {
      expect(wrapper.find('[data-testid="board-items-count"]').text()).toEqual(String(itemsSize));
    });

    it('contains maxIssueCount in the template', () => {
      expect(wrapper.find('.max-issue-size').text()).toContain(String(maxIssueCount));
    });

    it('has red text', () => {
      expect(wrapper.find('.gl-text-red-700').text()).toEqual(String(itemsSize));
    });
  });
});
