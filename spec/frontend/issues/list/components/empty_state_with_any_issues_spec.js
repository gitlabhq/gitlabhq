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
        isOpenTab: true,
        ...props,
      },
      provide: {
        emptyStateSvgPath: 'empty/state/svg/path',
        newIssuePath: 'new/issue/path',
        showNewIssueLink: false,
      },
    });
  };

  describe('when there is a search (with no results)', () => {
    beforeEach(() => {
      mountComponent({ hasSearch: true });
    });

    it('shows empty state', () => {
      expect(findGlEmptyState().props()).toMatchObject({
        description: 'To widen your search, change or remove filters above',
        title: 'Sorry, your filter produced no results',
        svgPath: 'empty/state/svg/path',
      });
    });
  });

  describe('when "Open" tab is active', () => {
    beforeEach(() => {
      mountComponent({ hasSearch: false, isOpenTab: true });
    });

    it('shows empty state', () => {
      expect(findGlEmptyState().props()).toMatchObject({
        description: 'To keep this project going, create a new issue',
        title: 'There are no open issues',
        svgPath: 'empty/state/svg/path',
      });
    });
  });

  describe('when "Closed" tab is active', () => {
    beforeEach(() => {
      mountComponent({ hasSearch: false, isOpenTab: false });
    });

    it('shows empty state', () => {
      expect(findGlEmptyState().props()).toMatchObject({
        title: 'There are no closed issues',
        svgPath: 'empty/state/svg/path',
      });
    });
  });
});
