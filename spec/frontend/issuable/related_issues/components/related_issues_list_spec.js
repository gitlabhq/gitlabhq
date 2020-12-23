import { mount, shallowMount } from '@vue/test-utils';
import {
  issuable1,
  issuable2,
  issuable3,
  issuable4,
  issuable5,
} from 'jest/vue_shared/components/issue/related_issuable_mock_data';
import IssueDueDate from '~/boards/components/issue_due_date.vue';
import RelatedIssuesList from '~/related_issues/components/related_issues_list.vue';
import { PathIdSeparator } from '~/related_issues/constants';

describe('RelatedIssuesList', () => {
  let wrapper;

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  describe('with defaults', () => {
    const heading = 'Related to';

    beforeEach(() => {
      wrapper = shallowMount(RelatedIssuesList, {
        propsData: {
          pathIdSeparator: PathIdSeparator.Issue,
          issuableType: 'issue',
          heading,
        },
      });
    });

    it('shows a heading', () => {
      expect(wrapper.find('h4').text()).toContain(heading);
    });

    it('should not show loading icon', () => {
      expect(wrapper.vm.$refs.loadingIcon).toBeUndefined();
    });
  });

  describe('with isFetching=true', () => {
    beforeEach(() => {
      wrapper = shallowMount(RelatedIssuesList, {
        propsData: {
          pathIdSeparator: PathIdSeparator.Issue,
          isFetching: true,
          issuableType: 'issue',
        },
      });
    });

    it('should show loading icon', () => {
      expect(wrapper.vm.$refs.loadingIcon).toBeDefined();
    });
  });

  describe('methods', () => {
    beforeEach(() => {
      wrapper = shallowMount(RelatedIssuesList, {
        propsData: {
          pathIdSeparator: PathIdSeparator.Issue,
          relatedIssues: [issuable1, issuable2, issuable3, issuable4, issuable5],
          issuableType: 'issue',
        },
      });
    });

    it('updates the order correctly when an item is moved to the top', () => {
      const beforeAfterIds = wrapper.vm.getBeforeAfterId(
        wrapper.vm.$el.querySelector('ul li:first-child'),
      );

      expect(beforeAfterIds.beforeId).toBeNull();
      expect(beforeAfterIds.afterId).toBe(2);
    });

    it('updates the order correctly when an item is moved to the bottom', () => {
      const beforeAfterIds = wrapper.vm.getBeforeAfterId(
        wrapper.vm.$el.querySelector('ul li:last-child'),
      );

      expect(beforeAfterIds.beforeId).toBe(4);
      expect(beforeAfterIds.afterId).toBeNull();
    });

    it('updates the order correctly when an item is swapped with adjacent item', () => {
      const beforeAfterIds = wrapper.vm.getBeforeAfterId(
        wrapper.vm.$el.querySelector('ul li:nth-child(3)'),
      );

      expect(beforeAfterIds.beforeId).toBe(2);
      expect(beforeAfterIds.afterId).toBe(4);
    });

    it('updates the order correctly when an item is moved somewhere in the middle', () => {
      const beforeAfterIds = wrapper.vm.getBeforeAfterId(
        wrapper.vm.$el.querySelector('ul li:nth-child(4)'),
      );

      expect(beforeAfterIds.beforeId).toBe(3);
      expect(beforeAfterIds.afterId).toBe(5);
    });
  });

  describe('issuableOrderingId returns correct issuable order id when', () => {
    it('issuableType is epic', () => {
      wrapper = shallowMount(RelatedIssuesList, {
        propsData: {
          pathIdSeparator: PathIdSeparator.Issue,
          issuableType: 'issue',
        },
      });

      expect(wrapper.vm.issuableOrderingId(issuable1)).toBe(issuable1.epicIssueId);
    });

    it('issuableType is issue', () => {
      wrapper = shallowMount(RelatedIssuesList, {
        propsData: {
          pathIdSeparator: PathIdSeparator.Issue,
          issuableType: 'epic',
        },
      });

      expect(wrapper.vm.issuableOrderingId(issuable1)).toBe(issuable1.id);
    });
  });

  describe('renders correct ordering id when', () => {
    let relatedIssues;

    beforeAll(() => {
      relatedIssues = [issuable1, issuable2, issuable3, issuable4, issuable5];
    });

    it('issuableType is epic', () => {
      wrapper = shallowMount(RelatedIssuesList, {
        propsData: {
          pathIdSeparator: PathIdSeparator.Issue,
          issuableType: 'epic',
          relatedIssues,
        },
      });

      const listItems = wrapper.vm.$el.querySelectorAll('.list-item');

      Array.from(listItems).forEach((item, index) => {
        expect(Number(item.dataset.orderingId)).toBe(relatedIssues[index].id);
      });
    });

    it('issuableType is issue', () => {
      wrapper = shallowMount(RelatedIssuesList, {
        propsData: {
          pathIdSeparator: PathIdSeparator.Issue,
          issuableType: 'issue',
          relatedIssues,
        },
      });

      const listItems = wrapper.vm.$el.querySelectorAll('.list-item');

      Array.from(listItems).forEach((item, index) => {
        expect(Number(item.dataset.orderingId)).toBe(relatedIssues[index].epicIssueId);
      });
    });
  });

  describe('related item contents', () => {
    beforeAll(() => {
      wrapper = mount(RelatedIssuesList, {
        propsData: {
          issuableType: 'issue',
          pathIdSeparator: PathIdSeparator.Issue,
          relatedIssues: [issuable1],
        },
      });
    });

    it('shows due date', () => {
      expect(wrapper.find(IssueDueDate).find('.board-card-info-text').text()).toBe('Nov 22, 2010');
    });
  });
});
