import { GlEmptyState } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import EmptyStateWithAnyIssues from '~/issues/service_desk/components/empty_state_with_any_issues.vue';
import {
  noSearchResultsTitle,
  noSearchResultsDescription,
  infoBannerUserNote,
  noOpenIssuesTitle,
  noClosedIssuesTitle,
} from '~/issues/service_desk/constants';

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
      mountComponent();
    });

    it('shows empty state', () => {
      expect(findGlEmptyState().props()).toMatchObject({
        description: noSearchResultsDescription,
        title: noSearchResultsTitle,
        svgPath: defaultProvide.emptyStateSvgPath,
      });
    });
  });

  describe('when "Open" tab is active', () => {
    beforeEach(() => {
      mountComponent({ hasSearch: false });
    });

    it('shows empty state', () => {
      expect(findGlEmptyState().props()).toMatchObject({
        description: infoBannerUserNote,
        title: noOpenIssuesTitle,
        svgPath: defaultProvide.emptyStateSvgPath,
      });
    });
  });

  describe('when "Closed" tab is active', () => {
    beforeEach(() => {
      mountComponent({ hasSearch: false, isClosedTab: true, isOpenTab: false });
    });

    it('shows empty state', () => {
      expect(findGlEmptyState().props()).toMatchObject({
        title: noClosedIssuesTitle,
        svgPath: defaultProvide.emptyStateSvgPath,
      });
    });
  });
});
