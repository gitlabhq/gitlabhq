import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import MergeRequestMenu from '~/super_sidebar/components/merge_request_menu.vue';
import UserCounts from '~/super_sidebar/components/user_counts.vue';
import { userCounts } from '~/super_sidebar/user_counts_manager';
import { fetchUserCounts } from '~/super_sidebar/user_counts_fetch';
import { sidebarData as mockSidebarData } from '../mock_data';

jest.mock('~/super_sidebar/user_counts_fetch');

describe('UserCounts component', () => {
  let wrapper;

  const findIssuesCounter = () => wrapper.findByTestId('issues-shortcut-button');
  const findMRsCounter = () => wrapper.findByTestId('merge-requests-shortcut-button');
  const findTodosCounter = () => wrapper.findByTestId('todos-shortcut-button');
  const findMergeRequestMenu = () => wrapper.findComponent(MergeRequestMenu);

  const createWrapper = ({ sidebarData = mockSidebarData } = {}) => {
    wrapper = shallowMountExtended(UserCounts, {
      propsData: {
        sidebarData,
      },
    });
  };

  describe('default', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders issues counter', () => {
      const issuesCounter = findIssuesCounter();
      expect(issuesCounter.props('count')).toBe(userCounts.assigned_issues);
      expect(issuesCounter.props('href')).toBe(mockSidebarData.issues_dashboard_path);
      expect(issuesCounter.props('label')).toBe('Assigned issues');
      expect(issuesCounter.attributes('data-track-action')).toBe('click_link');
      expect(issuesCounter.attributes('data-track-label')).toBe('issues_link');
      expect(issuesCounter.attributes('data-track-property')).toBe('nav_core_menu');
      expect(issuesCounter.attributes('class')).toContain('dashboard-shortcuts-issues');
    });

    it('renders merge requests counter', () => {
      const mrsCounter = findMRsCounter();
      expect(mrsCounter.props('count')).toBe(userCounts.total_merge_requests);
      expect(mrsCounter.props('label')).toBe('Merge requests');
      expect(mrsCounter.attributes('data-track-action')).toBe('click_dropdown');
      expect(mrsCounter.attributes('data-track-label')).toBe('merge_requests_menu');
      expect(mrsCounter.attributes('data-track-property')).toBe('nav_core_menu');
    });

    describe('Todos counter', () => {
      it('renders it', () => {
        const todosCounter = findTodosCounter();
        expect(todosCounter.props('count')).toBe(userCounts.todos);
        expect(todosCounter.props('href')).toBe(mockSidebarData.todos_dashboard_path);
        expect(todosCounter.props('label')).toBe('To-Do List');
        expect(todosCounter.attributes('data-track-action')).toBe('click_link');
        expect(todosCounter.attributes('data-track-label')).toBe('todos_link');
        expect(todosCounter.attributes('data-track-property')).toBe('nav_core_menu');
        expect(todosCounter.attributes('class')).toContain('shortcuts-todos');
      });

      it('should update todo counter when event with count is emitted', async () => {
        createWrapper();
        const count = 100;
        document.dispatchEvent(new CustomEvent('todo:toggle', { detail: { count } }));
        await nextTick();
        expect(findTodosCounter().props('count')).toBe(count);
      });

      it('should update todo counter when event with diff is emitted', async () => {
        createWrapper();
        expect(findTodosCounter().props('count')).toBe(3);
        document.dispatchEvent(new CustomEvent('todo:toggle', { detail: { delta: -2 } }));
        await nextTick();
        expect(findTodosCounter().props('count')).toBe(1);
      });
    });

    it('passes the "Merge request" menu groups to the merge_request_menu component', () => {
      expect(findMergeRequestMenu().props('items')).toBe(mockSidebarData.merge_request_menu);
    });
  });

  it('does not render merge request menu when merge_request_menu is null', () => {
    createWrapper({ sidebarData: { ...mockSidebarData, merge_request_menu: null } });

    expect(findMergeRequestMenu().exists()).toBe(false);
  });

  describe('merge request counts', () => {
    it('calls fetchUserCounts if merge requests count are null', () => {
      createWrapper({
        sidebarData: {
          ...mockSidebarData,
          user_counts: {
            ...mockSidebarData.user_counts,
            review_requested_merge_requests: null,
            assigned_merge_requests: null,
          },
        },
      });

      expect(fetchUserCounts).toHaveBeenCalled();
    });

    it('does not call fetchUserCounts if merge requests count exist', () => {
      createWrapper({
        sidebarData: {
          ...mockSidebarData,
          user_counts: {
            ...mockSidebarData.user_counts,
            review_requested_merge_requests: 3,
            assigned_merge_requests: 3,
          },
        },
      });

      expect(fetchUserCounts).not.toHaveBeenCalled();
    });
  });
});
