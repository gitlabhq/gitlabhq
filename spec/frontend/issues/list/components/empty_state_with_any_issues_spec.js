import { GlEmptyState } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import EmptyStateWithAnyIssues from '~/issues/list/components/empty_state_with_any_issues.vue';

describe('EmptyStateWithAnyIssues component', () => {
  let wrapper;

  const findGlEmptyState = () => wrapper.findComponent(GlEmptyState);

  const mountComponent = (props = {}) => {
    wrapper = shallowMount(EmptyStateWithAnyIssues, {
      propsData: {
        hasSearch: true,
        isEpic: false,
        isOpenTab: true,
        ...props,
      },
      provide: {
        newIssuePath: 'new/issue/path',
        showNewIssueLink: false,
      },
    });
  };

  describe('when there is a search (with no results)', () => {
    it('shows empty state', () => {
      mountComponent({ hasSearch: true });

      expect(findGlEmptyState().props()).toMatchObject({
        description: 'To widen your search, change or remove filters above',
        title: 'Sorry, your filter produced no results',
      });
    });
  });

  describe('when "Open" tab is active', () => {
    it('shows empty state', () => {
      mountComponent({ hasSearch: false, isOpenTab: true });

      expect(findGlEmptyState().props('title')).toBe('There are no open issues');
    });
  });

  describe('when "Closed" tab is active', () => {
    it('shows empty state', () => {
      mountComponent({ hasSearch: false, isOpenTab: false });

      expect(findGlEmptyState().props('title')).toBe('There are no closed issues');
    });
  });

  describe('when epic', () => {
    describe('when "Open" tab is active', () => {
      it('shows empty state', () => {
        mountComponent({ hasSearch: false, isEpic: true, isOpenTab: true });

        expect(findGlEmptyState().props('title')).toBe('There are no open epics');
      });
    });

    describe('when "Closed" tab is active', () => {
      it('shows empty state', () => {
        mountComponent({ hasSearch: false, isEpic: true, isOpenTab: false });

        expect(findGlEmptyState().props('title')).toBe('There are no closed epics');
      });
    });
  });
});
