import { GlEmptyState } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import EmptyStateWithAnyIssues from '~/issues/list/components/empty_state_with_any_issues.vue';
import IssuesListApp from '~/issues/list/components/issues_list_app.vue';

describe('EmptyStateWithAnyIssues component', () => {
  let wrapper;

  const defaultProvide = {
    emptyStateSvgPath: 'empty/state/svg/path',
    newIssuePath: 'new/issue/path',
    showNewIssueLink: false,
  };

  const findGlEmptyState = () => wrapper.findComponent(GlEmptyState);

  const mountComponent = (props = {}) => {
    wrapper = shallowMount(EmptyStateWithAnyIssues, {
      propsData: {
        hasSearch: true,
        isOpenTab: true,
        ...props,
      },
      provide: defaultProvide,
    });
  };

  describe('when there is a search (with no results)', () => {
    beforeEach(() => {
      mountComponent({ hasSearch: true });
    });

    it('shows empty state', () => {
      expect(findGlEmptyState().props()).toMatchObject({
        description: IssuesListApp.i18n.noSearchResultsDescription,
        title: IssuesListApp.i18n.noSearchResultsTitle,
        svgPath: defaultProvide.emptyStateSvgPath,
      });
    });
  });

  describe('when "Open" tab is active', () => {
    beforeEach(() => {
      mountComponent({ hasSearch: false, isOpenTab: true });
    });

    it('shows empty state', () => {
      expect(findGlEmptyState().props()).toMatchObject({
        description: IssuesListApp.i18n.noOpenIssuesDescription,
        title: IssuesListApp.i18n.noOpenIssuesTitle,
        svgPath: defaultProvide.emptyStateSvgPath,
      });
    });
  });

  describe('when "Closed" tab is active', () => {
    beforeEach(() => {
      mountComponent({ hasSearch: false, isOpenTab: false });
    });

    it('shows empty state', () => {
      expect(findGlEmptyState().props()).toMatchObject({
        title: IssuesListApp.i18n.noClosedIssuesTitle,
        svgPath: defaultProvide.emptyStateSvgPath,
      });
    });
  });
});
