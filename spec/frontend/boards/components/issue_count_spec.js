import { shallowMount } from '@vue/test-utils';
import IssueCount from '~/boards/components/issue_count.vue';

describe('IssueCount', () => {
  let vm;
  let maxIssueCount;
  let issuesSize;

  const createComponent = props => {
    vm = shallowMount(IssueCount, { propsData: props });
  };

  afterEach(() => {
    maxIssueCount = 0;
    issuesSize = 0;

    if (vm) vm.destroy();
  });

  describe('when maxIssueCount is zero', () => {
    beforeEach(() => {
      issuesSize = 3;

      createComponent({ maxIssueCount: 0, issuesSize });
    });

    it('contains issueSize in the template', () => {
      expect(vm.find('.js-issue-size').text()).toEqual(String(issuesSize));
    });

    it('does not contains maxIssueCount in the template', () => {
      expect(vm.contains('.js-max-issue-size')).toBe(false);
    });
  });

  describe('when maxIssueCount is greater than zero', () => {
    beforeEach(() => {
      maxIssueCount = 2;
      issuesSize = 1;

      createComponent({ maxIssueCount, issuesSize });
    });

    afterEach(() => {
      vm.destroy();
    });

    it('contains issueSize in the template', () => {
      expect(vm.find('.js-issue-size').text()).toEqual(String(issuesSize));
    });

    it('contains maxIssueCount in the template', () => {
      expect(vm.find('.js-max-issue-size').text()).toEqual(String(maxIssueCount));
    });

    it('does not have text-danger class when issueSize is less than maxIssueCount', () => {
      expect(vm.classes('.text-danger')).toBe(false);
    });
  });

  describe('when issueSize is greater than maxIssueCount', () => {
    beforeEach(() => {
      issuesSize = 3;
      maxIssueCount = 2;

      createComponent({ maxIssueCount, issuesSize });
    });

    afterEach(() => {
      vm.destroy();
    });

    it('contains issueSize in the template', () => {
      expect(vm.find('.js-issue-size').text()).toEqual(String(issuesSize));
    });

    it('contains maxIssueCount in the template', () => {
      expect(vm.find('.js-max-issue-size').text()).toEqual(String(maxIssueCount));
    });

    it('has text-danger class', () => {
      expect(vm.find('.text-danger').text()).toEqual(String(issuesSize));
    });
  });
});
