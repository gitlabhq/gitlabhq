import { GlEmptyState } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import IssuesDashboardApp from '~/issues/dashboard/components/issues_dashboard_app.vue';
import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';
import { IssuableStates } from '~/vue_shared/issuable/list/constants';

describe('IssuesDashboardApp component', () => {
  let wrapper;

  const defaultProvide = {
    calendarPath: 'calendar/path',
    emptyStateSvgPath: 'empty-state.svg',
    isSignedIn: true,
    rssPath: 'rss/path',
  };

  const findCalendarButton = () =>
    wrapper.findByRole('link', { name: IssuesDashboardApp.i18n.calendarButtonText });
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findIssuableList = () => wrapper.findComponent(IssuableList);
  const findRssButton = () =>
    wrapper.findByRole('link', { name: IssuesDashboardApp.i18n.rssButtonText });

  const mountComponent = () => {
    wrapper = mountExtended(IssuesDashboardApp, { provide: defaultProvide });
  };

  beforeEach(() => {
    mountComponent();
  });

  it('renders IssuableList component', () => {
    expect(findIssuableList().props()).toMatchObject({
      currentTab: IssuableStates.Opened,
      namespace: 'dashboard',
      recentSearchesStorageKey: 'issues',
      searchInputPlaceholder: IssuesDashboardApp.i18n.searchInputPlaceholder,
      tabs: IssuesDashboardApp.IssuableListTabs,
    });
  });

  it('renders RSS button link', () => {
    expect(findRssButton().attributes('href')).toBe(defaultProvide.rssPath);
    expect(findRssButton().props('icon')).toBe('rss');
  });

  it('renders calendar button link', () => {
    expect(findCalendarButton().attributes('href')).toBe(defaultProvide.calendarPath);
    expect(findCalendarButton().props('icon')).toBe('calendar');
  });

  it('renders empty state', () => {
    expect(findEmptyState().props()).toMatchObject({
      svgPath: defaultProvide.emptyStateSvgPath,
      title: IssuesDashboardApp.i18n.emptyStateTitle,
    });
  });
});
