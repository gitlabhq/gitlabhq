import { GlEmptyState } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { cloneDeep } from 'lodash';
import getIssuesQuery from 'ee_else_ce/issues/dashboard/queries/get_issues.query.graphql';
import IssueCardStatistics from 'ee_else_ce/issues/list/components/issue_card_statistics.vue';
import IssueCardTimeInfo from 'ee_else_ce/issues/list/components/issue_card_time_info.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import setWindowLocation from 'helpers/set_window_location_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  setSortPreferenceMutationResponse,
  setSortPreferenceMutationResponseWithErrors,
} from 'jest/issues/list/mock_data';
import IssuesDashboardApp from '~/issues/dashboard/components/issues_dashboard_app.vue';
import { CREATED_DESC, i18n, UPDATED_DESC, urlSortParams } from '~/issues/list/constants';
import setSortPreferenceMutation from '~/issues/list/queries/set_sort_preference.mutation.graphql';
import { getSortKey, getSortOptions } from '~/issues/list/utils';
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
    initialSort: CREATED_DESC,
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
    provide = {},
    issuesQueryHandler = jest.fn().mockResolvedValue(defaultQueryResponse),
    sortPreferenceMutationResponse = jest.fn().mockResolvedValue(setSortPreferenceMutationResponse),
  } = {}) => {
    wrapper = mountExtended(IssuesDashboardApp, {
      apolloProvider: createMockApollo([
        [getIssuesQuery, issuesQueryHandler],
        [setSortPreferenceMutation, sortPreferenceMutationResponse],
      ]),
      provide: {
        ...defaultProvide,
        ...provide,
      },
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
      initialSortBy: CREATED_DESC,
      issuables: issuesQueryResponse.data.issues.nodes,
      issuablesLoading: false,
      namespace: 'dashboard',
      recentSearchesStorageKey: 'issues',
      searchInputPlaceholder: IssuesDashboardApp.i18n.searchInputPlaceholder,
      showPaginationControls: true,
      sortOptions: getSortOptions({
        hasBlockedIssuesFeature: defaultProvide.hasBlockedIssuesFeature,
        hasIssuableHealthStatusFeature: defaultProvide.hasIssuableHealthStatusFeature,
        hasIssueWeightsFeature: defaultProvide.hasIssueWeightsFeature,
      }),
      tabs: IssuesDashboardApp.IssuableListTabs,
      urlParams: {
        sort: urlSortParams[CREATED_DESC],
        state: IssuableStates.Opened,
      },
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

  describe('initial url params', () => {
    describe('sort', () => {
      describe('when initial sort value uses old enum values', () => {
        const oldEnumSortValues = Object.values(urlSortParams);

        it.each(oldEnumSortValues)('initial sort is set with value %s', (sort) => {
          mountComponent({ provide: { initialSort: sort } });

          expect(findIssuableList().props('initialSortBy')).toBe(getSortKey(sort));
        });
      });

      describe('when initial sort value uses new GraphQL enum values', () => {
        const graphQLEnumSortValues = Object.keys(urlSortParams);

        it.each(graphQLEnumSortValues)('initial sort is set with value %s', (sort) => {
          mountComponent({ provide: { initialSort: sort.toLowerCase() } });

          expect(findIssuableList().props('initialSortBy')).toBe(sort);
        });
      });

      describe('when initial sort value is invalid', () => {
        it.each(['', 'asdf', null, undefined])(
          'initial sort is set to value CREATED_DESC',
          (sort) => {
            mountComponent({ provide: { initialSort: sort } });

            expect(findIssuableList().props('initialSortBy')).toBe(CREATED_DESC);
          },
        );
      });
    });

    describe('state', () => {
      it('is set from the url params', () => {
        const initialState = IssuableStates.All;
        setWindowLocation(`?state=${initialState}`);
        mountComponent();

        expect(findIssuableList().props('currentTab')).toBe(initialState);
      });
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

      it('updates url to the new tab', () => {
        expect(findIssuableList().props('urlParams')).toMatchObject({
          state: IssuableStates.Closed,
        });
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

    describe('when "sort" event is emitted by IssuableList', () => {
      it.each(Object.keys(urlSortParams))(
        'updates to the new sort when payload is `%s`',
        async (sortKey) => {
          // Ensure initial sort key is different so we can trigger an update when emitting a sort key
          if (sortKey === CREATED_DESC) {
            mountComponent({ provide: { initialSort: UPDATED_DESC } });
          } else {
            mountComponent();
          }

          findIssuableList().vm.$emit('sort', sortKey);
          await nextTick();

          expect(findIssuableList().props('urlParams')).toMatchObject({
            sort: urlSortParams[sortKey],
          });
        },
      );

      describe('when user is signed in', () => {
        it('calls mutation to save sort preference', () => {
          const mutationMock = jest.fn().mockResolvedValue(setSortPreferenceMutationResponse);
          mountComponent({ sortPreferenceMutationResponse: mutationMock });

          findIssuableList().vm.$emit('sort', UPDATED_DESC);

          expect(mutationMock).toHaveBeenCalledWith({ input: { issuesSort: UPDATED_DESC } });
        });

        it('captures error when mutation response has errors', async () => {
          const mutationMock = jest
            .fn()
            .mockResolvedValue(setSortPreferenceMutationResponseWithErrors);
          mountComponent({ sortPreferenceMutationResponse: mutationMock });

          findIssuableList().vm.$emit('sort', UPDATED_DESC);
          await waitForPromises();

          expect(Sentry.captureException).toHaveBeenCalledWith(new Error('oh no!'));
        });
      });

      describe('when user is signed out', () => {
        it('does not call mutation to save sort preference', () => {
          const mutationMock = jest.fn().mockResolvedValue(setSortPreferenceMutationResponse);
          mountComponent({
            provide: { isSignedIn: false },
            sortPreferenceMutationResponse: mutationMock,
          });

          findIssuableList().vm.$emit('sort', CREATED_DESC);

          expect(mutationMock).not.toHaveBeenCalled();
        });
      });
    });
  });
});
