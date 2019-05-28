import Vue from 'vue';

import IssueAssignees from '~/vue_shared/components/issue/issue_assignees.vue';

import mountComponent from 'helpers/vue_mount_component_helper';
import { mockAssigneesList } from '../../../../javascripts/boards/mock_data';

const createComponent = (assignees = mockAssigneesList, cssClass = '') => {
  const Component = Vue.extend(IssueAssignees);

  return mountComponent(Component, {
    assignees,
    cssClass,
  });
};

describe('IssueAssigneesComponent', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('data', () => {
    it('returns default data props', () => {
      expect(vm.maxVisibleAssignees).toBe(2);
      expect(vm.maxAssigneeAvatars).toBe(3);
      expect(vm.maxAssignees).toBe(99);
    });
  });

  describe('computed', () => {
    describe('countOverLimit', () => {
      it('should return difference between assignees count and maxVisibleAssignees', () => {
        expect(vm.countOverLimit).toBe(mockAssigneesList.length - vm.maxVisibleAssignees);
      });
    });

    describe('assigneesToShow', () => {
      it('should return assignees containing only 2 items when count more than maxAssigneeAvatars', () => {
        expect(vm.assigneesToShow.length).toBe(2);
      });

      it('should return all assignees as it is when count less than maxAssigneeAvatars', () => {
        vm.assignees = mockAssigneesList.slice(0, 3); // Set 3 Assignees

        expect(vm.assigneesToShow.length).toBe(3);
      });
    });

    describe('assigneesCounterTooltip', () => {
      it('should return string containing count of remaining assignees when count more than maxAssigneeAvatars', () => {
        expect(vm.assigneesCounterTooltip).toBe('3 more assignees');
      });
    });

    describe('shouldRenderAssigneesCounter', () => {
      it('should return `false` when assignees count less than maxAssigneeAvatars', () => {
        vm.assignees = mockAssigneesList.slice(0, 3); // Set 3 Assignees

        expect(vm.shouldRenderAssigneesCounter).toBe(false);
      });

      it('should return `true` when assignees count more than maxAssigneeAvatars', () => {
        expect(vm.shouldRenderAssigneesCounter).toBe(true);
      });
    });

    describe('assigneeCounterLabel', () => {
      it('should return count of additional assignees total assignees count more than maxAssigneeAvatars', () => {
        expect(vm.assigneeCounterLabel).toBe('+3');
      });
    });
  });

  describe('methods', () => {
    describe('avatarUrlTitle', () => {
      it('returns string containing alt text for assignee avatar', () => {
        expect(vm.avatarUrlTitle(mockAssigneesList[0])).toBe('Avatar for Terrell Graham');
      });
    });
  });

  describe('template', () => {
    it('renders component root element with class `issue-assignees`', () => {
      expect(vm.$el.classList.contains('issue-assignees')).toBe(true);
    });

    it('renders assignee avatars', () => {
      expect(vm.$el.querySelectorAll('.user-avatar-link').length).toBe(2);
    });

    it('renders assignee tooltips', () => {
      const tooltipText = vm.$el
        .querySelectorAll('.user-avatar-link')[0]
        .querySelector('.js-assignee-tooltip').innerText;

      expect(tooltipText).toContain('Assignee');
      expect(tooltipText).toContain('Terrell Graham');
      expect(tooltipText).toContain('@monserrate.gleichner');
    });

    it('renders additional assignees count', () => {
      const avatarCounterEl = vm.$el.querySelector('.avatar-counter');

      expect(avatarCounterEl.innerText.trim()).toBe('+3');
      expect(avatarCounterEl.getAttribute('data-original-title')).toBe('3 more assignees');
    });
  });
});
