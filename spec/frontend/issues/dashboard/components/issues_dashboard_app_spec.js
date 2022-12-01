import { GlEmptyState } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { cloneDeep } from 'lodash';
import getIssuesQuery from 'ee_else_ce/issues/dashboard/queries/get_issues.query.graphql';
import IssueCardStatistics from 'ee_else_ce/issues/list/components/issue_card_statistics.vue';
import IssueCardTimeInfo from 'ee_else_ce/issues/list/components/issue_card_time_info.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import IssuesDashboardApp from '~/issues/dashboard/components/issues_dashboard_app.vue';
import { i18n } from '~/issues/list/constants';
import { scrollUp } from '~/lib/utils/scroll_utils';
import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';
import { IssuableStates } from '~/vue_shared/issuable/list/constants';
import { emptyIssuesQueryResponse, issuesQueryResponse } from '../mock_data';

jest.mock('@sentry/browser');
jest.mock('~/lib/utils/scroll_utils', () => ({ scrollUp: jest.fn() }));

describe('IssuesDashboardApp component', () => {
  let wrapper;

  Vue.use(VueApollo);

  const defaultProvide = {
    calendarPath: 'calendar/path',
    emptyStateSvgPath: 'empty-state.svg',
    hasBlockedIssuesFeature: true,
    hasIssuableHealthStatusFeature: true,
    hasIssueWeightsFeature: true,
    hasScopedLabelsFeature: true,
    isPublicVisibilityRestricted: false,
    isSignedIn: true,
    rssPath: 'rss/path',
  };

  let defaultQueryResponse = issuesQueryResponse;
  if (IS_EE) {
    defaultQueryResponse = cloneDeep(issuesQueryResponse);
    defaultQueryResponse.data.issues.nodes[0].blockingCount = 1;
    defaultQueryResponse.data.issues.nodes[0].healthStatus = null;
    defaultQueryResponse.data.issues.nodes[0].weight = 5;
  }

  const findCalendarButton = () =>
    wrapper.findByRole('link', { name: IssuesDashboardApp.i18n.calendarButtonText });
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findIssuableList = () => wrapper.findComponent(IssuableList);
  const findIssueCardStatistics = () => wrapper.findComponent(IssueCardStatistics);
  const findIssueCardTimeInfo = () => wrapper.findComponent(IssueCardTimeInfo);
  const findRssButton = () =>
    wrapper.findByRole('link', { name: IssuesDashboardApp.i18n.rssButtonText });

  const mountComponent = ({
    issuesQueryHandler = jest.fn().mockResolvedValue(defaultQueryResponse),
  } = {}) => {
    wrapper = mountExtended(IssuesDashboardApp, {
      apolloProvider: createMockApollo([[getIssuesQuery, issuesQueryHandler]]),
      provide: defaultProvide,
    });
  };

  it('renders IssuableList component', async () => {
    mountComponent();
    await waitForPromises();

    expect(findIssuableList().props()).toMatchObject({
      currentTab: IssuableStates.Opened,
      hasNextPage: true,
      hasPreviousPage: false,
      hasScopedLabelsFeature: defaultProvide.hasScopedLabelsFeature,
      namespace: 'dashboard',
      recentSearchesStorageKey: 'issues',
      searchInputPlaceholder: IssuesDashboardApp.i18n.searchInputPlaceholder,
      showPaginationControls: true,
      tabs: IssuesDashboardApp.IssuableListTabs,
      useKeysetPagination: true,
    });
  });

  it('renders RSS button link', () => {
    mountComponent();

    expect(findRssButton().attributes('href')).toBe(defaultProvide.rssPath);
    expect(findRssButton().props('icon')).toBe('rss');
  });

  it('renders calendar button link', () => {
    mountComponent();

    expect(findCalendarButton().attributes('href')).toBe(defaultProvide.calendarPath);
    expect(findCalendarButton().props('icon')).toBe('calendar');
  });

  it('renders issue time information', async () => {
    mountComponent();
    await waitForPromises();

    expect(findIssueCardTimeInfo().exists()).toBe(true);
  });

  it('renders issue statistics', async () => {
    mountComponent();
    await waitForPromises();

    expect(findIssueCardStatistics().exists()).toBe(true);
  });

  it('renders empty state', async () => {
    mountComponent({ issuesQueryHandler: jest.fn().mockResolvedValue(emptyIssuesQueryResponse) });
    await waitForPromises();

    expect(findEmptyState().props()).toMatchObject({
      svgPath: defaultProvide.emptyStateSvgPath,
      title: IssuesDashboardApp.i18n.emptyStateTitle,
    });
  });

  describe('when there is an error fetching issues', () => {
    beforeEach(() => {
      mountComponent({ issuesQueryHandler: jest.fn().mockRejectedValue(new Error('ERROR')) });
      return waitForPromises();
    });

    it('shows an error message', () => {
      expect(findIssuableList().props('error')).toBe(i18n.errorFetchingIssues);
      expect(Sentry.captureException).toHaveBeenCalledWith(new Error('ERROR'));
    });

    it('clears error message when "dismiss-alert" event is emitted from IssuableList', async () => {
      findIssuableList().vm.$emit('dismiss-alert');
      await nextTick();

      expect(findIssuableList().props('error')).toBeNull();
    });
  });

  describe('events', () => {
    describe('when "click-tab" event is emitted by IssuableList', () => {
      beforeEach(() => {
        mountComponent();

        findIssuableList().vm.$emit('click-tab', IssuableStates.Closed);
      });

      it('updates ui to the new tab', () => {
        expect(findIssuableList().props('currentTab')).toBe(IssuableStates.Closed);
      });
    });

    describe.each(['next-page', 'previous-page'])(
      'when "%s" event is emitted by IssuableList',
      (event) => {
        beforeEach(() => {
          mountComponent();

          findIssuableList().vm.$emit(event);
        });

        it('scrolls to the top', () => {
          expect(scrollUp).toHaveBeenCalled();
        });
      },
    );
  });
});
