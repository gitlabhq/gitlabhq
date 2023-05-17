import { mount, shallowMount } from '@vue/test-utils';
import {
  issuable1,
  issuable2,
  issuable3,
  issuable4,
  issuable5,
} from 'jest/issuable/components/related_issuable_mock_data';
import IssueDueDate from '~/boards/components/issue_due_date.vue';
import RelatedIssuesList from '~/related_issues/components/related_issues_list.vue';
import { PathIdSeparator } from '~/related_issues/constants';

describe('RelatedIssuesList', () => {
  let wrapper;

  const createComponent = ({
    mountFn = shallowMount,
    pathIdSeparator = PathIdSeparator.Issue,
    issuableType = 'issue',
    listLinkType = 'relates_to',
    heading = '',
    isFetching = false,
    relatedIssues = [],
  } = {}) => {
    wrapper = mountFn(RelatedIssuesList, {
      propsData: {
        pathIdSeparator,
        issuableType,
        listLinkType,
        heading,
        isFetching,
        relatedIssues,
      },
      provide: {
        reportAbusePath: '/report/abuse/path',
      },
    });
  };

  describe('with defaults', () => {
    const heading = 'Related to';

    beforeEach(() => {
      createComponent({ heading });
    });

    it('assigns value of listLinkType prop to data attribute', () => {
      expect(wrapper.attributes('data-link-type')).toBe('relates_to');
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
      createComponent({ isFetching: true });
    });

    it('should show loading icon', () => {
      expect(wrapper.vm.$refs.loadingIcon).toBeDefined();
    });
  });

  describe('methods', () => {
    beforeEach(() => {
      createComponent({ relatedIssues: [issuable1, issuable2, issuable3, issuable4, issuable5] });
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
    it('issuableType is issue', () => {
      createComponent({
        issuableType: 'issue',
      });

      expect(wrapper.vm.issuableOrderingId(issuable1)).toBe(issuable1.epicIssueId);
    });

    it('issuableType is epic', () => {
      createComponent({
        issuableType: 'epic',
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
      createComponent({
        issuableType: 'epic',
        relatedIssues,
      });

      const listItems = wrapper.vm.$el.querySelectorAll('.list-item');

      Array.from(listItems).forEach((item, index) => {
        expect(Number(item.dataset.orderingId)).toBe(relatedIssues[index].id);
      });
    });

    it('issuableType is issue', () => {
      createComponent({
        issuableType: 'issue',
        relatedIssues,
      });

      const listItems = wrapper.vm.$el.querySelectorAll('.list-item');

      Array.from(listItems).forEach((item, index) => {
        expect(Number(item.dataset.orderingId)).toBe(relatedIssues[index].epicIssueId);
      });
    });
  });

  describe('related item contents', () => {
    beforeAll(() => {
      createComponent({ mountFn: mount, relatedIssues: [issuable1] });
    });

    it('shows due date', () => {
      expect(wrapper.findComponent(IssueDueDate).find('.board-card-info-text').text()).toBe(
        'Nov 22, 2010',
      );
    });
  });
});
