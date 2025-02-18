import { GlLoadingIcon, GlAlert, GlIntersectionObserver } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import JobsTableTabs from '~/ci/jobs_page/components/jobs_table_tabs.vue';
import JobsSkeletonLoader from '~/ci/admin/jobs_table/components/jobs_skeleton_loader.vue';
import JobsTableEmptyState from '~/ci/jobs_page/components/jobs_table_empty_state.vue';
import getAllJobsQuery from '~/ci/admin/jobs_table/graphql/queries/get_all_jobs.query.graphql';
import getAllJobsCount from '~/ci/admin/jobs_table/graphql/queries/get_all_jobs_count.query.graphql';
import getCancelableJobsQuery from '~/ci/admin/jobs_table/graphql/queries/get_cancelable_jobs_count.query.graphql';
import AdminJobsTableApp from '~/ci/admin/jobs_table/admin_jobs_table_app.vue';
import CancelJobs from '~/ci/admin/jobs_table/components/cancel_jobs.vue';
import JobsTable from '~/ci/jobs_page/components/jobs_table.vue';
import { createAlert } from '~/alert';
import { TEST_HOST } from 'spec/test_constants';
import JobsFilteredSearch from '~/ci/common/private/jobs_filtered_search/app.vue';
import * as urlUtils from '~/lib/utils/url_utility';
import {
  JOBS_FETCH_ERROR_MSG,
  CANCELABLE_JOBS_ERROR_MSG,
  LOADING_ARIA_LABEL,
  RAW_TEXT_WARNING_ADMIN,
  JOBS_COUNT_ERROR_MESSAGE,
} from '~/ci/admin/jobs_table/constants';
import { TOKEN_TYPE_JOBS_RUNNER_TYPE } from '~/vue_shared/components/filtered_search_bar/constants';
import {
  mockAllJobsResponsePaginated,
  mockCancelableJobsCountResponse,
  mockAllJobsResponseEmpty,
  statuses,
  mockFailedSearchToken,
  mockAllJobsCountResponse,
} from 'jest/ci/jobs_mock_data';

Vue.use(VueApollo);

jest.mock('~/alert');

describe('Job table app', () => {
  let wrapper;

  const successHandler = jest.fn().mockResolvedValue(mockAllJobsResponsePaginated);
  const failedHandler = jest.fn().mockRejectedValue(new Error('GraphQL error'));
  const cancelHandler = jest.fn().mockResolvedValue(mockCancelableJobsCountResponse);
  const emptyHandler = jest.fn().mockResolvedValue(mockAllJobsResponseEmpty);
  const countSuccessHandler = jest.fn().mockResolvedValue(mockAllJobsCountResponse);

  const findSkeletonLoader = () => wrapper.findComponent(JobsSkeletonLoader);
  const findLoadingSpinner = () => wrapper.findComponent(GlLoadingIcon);
  const findTable = () => wrapper.findComponent(JobsTable);
  const findEmptyState = () => wrapper.findComponent(JobsTableEmptyState);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findTabs = () => wrapper.findComponent(JobsTableTabs);
  const findCancelJobsButton = () => wrapper.findComponent(CancelJobs);
  const findFilteredSearch = () => wrapper.findComponent(JobsFilteredSearch);

  const mockSearchTokenRunnerType = {
    type: TOKEN_TYPE_JOBS_RUNNER_TYPE,
    value: { data: 'INSTANCE_TYPE', operator: '=' },
  };

  const triggerInfiniteScroll = () =>
    wrapper.findComponent(GlIntersectionObserver).vm.$emit('appear');

  const createMockApolloProvider = (handler, cancelableHandler, countHandler) => {
    const requestHandlers = [
      [getAllJobsQuery, handler],
      [getCancelableJobsQuery, cancelableHandler],
      [getAllJobsCount, countHandler],
    ];

    return createMockApollo(requestHandlers);
  };

  const createComponent = ({
    handler = successHandler,
    cancelableHandler = cancelHandler,
    countHandler = countSuccessHandler,
    data = {},
    provideOptions = {},
    stubs = {},
  } = {}) => {
    wrapper = shallowMount(AdminJobsTableApp, {
      data() {
        return {
          ...data,
        };
      },
      provide: {
        jobStatuses: statuses,
        glFeatures: { adminJobsFilterRunnerType: true },
        ...provideOptions,
      },
      apolloProvider: createMockApolloProvider(handler, cancelableHandler, countHandler),
      stubs,
    });
  };

  describe('loading state', () => {
    it('should display skeleton loader when loading', () => {
      createComponent();

      expect(findSkeletonLoader().exists()).toBe(true);
      expect(findTable().exists()).toBe(false);
      expect(findLoadingSpinner().exists()).toBe(false);
    });

    it('when switching tabs only the skeleton loader should show', () => {
      createComponent();

      findTabs().vm.$emit('fetchJobsByStatus', null);

      expect(findSkeletonLoader().exists()).toBe(true);
      expect(findLoadingSpinner().exists()).toBe(false);
    });
  });

  describe('loaded state', () => {
    beforeEach(async () => {
      createComponent();

      await waitForPromises();
    });

    it('should display the jobs table with data', () => {
      expect(findTable().exists()).toBe(true);
      expect(findSkeletonLoader().exists()).toBe(false);
      expect(findLoadingSpinner().exists()).toBe(false);
    });

    it('should refetch jobs query on fetchJobsByStatus event', async () => {
      expect(successHandler).toHaveBeenCalledTimes(1);

      await findTabs().vm.$emit('fetchJobsByStatus');

      expect(successHandler).toHaveBeenCalledTimes(2);
    });

    it('avoids refetch jobs query when scope has not changed', async () => {
      expect(successHandler).toHaveBeenCalledTimes(1);

      await findTabs().vm.$emit('fetchJobsByStatus', null);

      expect(successHandler).toHaveBeenCalledTimes(1);
    });

    it('should refetch jobs count query when the amount jobs and count do not match', async () => {
      expect(countSuccessHandler).toHaveBeenCalledTimes(1);

      // after applying filter a new count is fetched
      findFilteredSearch().vm.$emit('filterJobsBySearch', [mockFailedSearchToken]);

      expect(successHandler).toHaveBeenCalledTimes(2);

      // tab is switched to `finished`, no count
      await findTabs().vm.$emit('fetchJobsByStatus', ['FAILED', 'SUCCESS', 'CANCELED']);

      // tab is switched back to `all`, the old filter count has to be overwritten with new count
      await findTabs().vm.$emit('fetchJobsByStatus', null);

      expect(successHandler).toHaveBeenCalledTimes(4);
    });

    describe('when infinite scrolling is triggered', () => {
      it('does not display a skeleton loader', () => {
        triggerInfiniteScroll();

        expect(findSkeletonLoader().exists()).toBe(false);
      });

      it('handles infinite scrolling by calling fetch more', async () => {
        triggerInfiniteScroll();

        await nextTick();

        const pageSize = 50;

        expect(findLoadingSpinner().exists()).toBe(true);
        expect(findLoadingSpinner().attributes('aria-label')).toBe(LOADING_ARIA_LABEL);

        await waitForPromises();

        expect(findLoadingSpinner().exists()).toBe(false);

        expect(successHandler).toHaveBeenLastCalledWith({
          first: pageSize,
          after: mockAllJobsResponsePaginated.data.jobs.pageInfo.endCursor,
        });
      });
    });
  });

  describe('empty state', () => {
    it('should display empty state if there are no jobs and tab scope is null', async () => {
      createComponent({ handler: emptyHandler });

      await waitForPromises();

      expect(findEmptyState().exists()).toBe(true);
      expect(findTable().exists()).toBe(false);
    });

    it('should not display empty state if there are jobs and tab scope is not null', async () => {
      createComponent({ handler: successHandler });

      await waitForPromises();

      expect(findEmptyState().exists()).toBe(false);
      expect(findTable().exists()).toBe(true);
    });
  });

  describe('error state', () => {
    it('should show an alert if there is an error fetching the jobs data', async () => {
      createComponent({ handler: failedHandler });

      await waitForPromises();

      expect(findAlert().text()).toBe(JOBS_FETCH_ERROR_MSG);
      expect(findTable().exists()).toBe(false);
    });

    it('should show an alert if there is an error fetching the jobs count data', async () => {
      createComponent({ handler: successHandler, countHandler: failedHandler });

      await waitForPromises();

      expect(findAlert().text()).toBe(JOBS_COUNT_ERROR_MESSAGE);
    });

    it('should show an alert if there is an error fetching the cancelable jobs data', async () => {
      createComponent({ handler: successHandler, cancelableHandler: failedHandler });

      await waitForPromises();

      expect(findAlert().text()).toBe(CANCELABLE_JOBS_ERROR_MSG);
    });

    it('jobs table should still load if count query fails', async () => {
      createComponent({ handler: successHandler, countHandler: failedHandler });

      await waitForPromises();

      expect(findTable().exists()).toBe(true);
    });

    it('jobs table should still load if cancel query fails', async () => {
      createComponent({ handler: successHandler, cancelableHandler: failedHandler });

      await waitForPromises();

      expect(findTable().exists()).toBe(true);
    });

    it('jobs count should be zero if count query fails', async () => {
      createComponent({ handler: successHandler, countHandler: failedHandler });

      await waitForPromises();

      expect(findTabs().props('allJobsCount')).toBe(0);
    });

    it('cancel button should be hidden if query fails', async () => {
      createComponent({ handler: successHandler, cancelableHandler: failedHandler });

      await waitForPromises();

      expect(findCancelJobsButton().exists()).toBe(false);
    });
  });

  describe('cancel jobs button', () => {
    describe('when there are cancelable jobs', () => {
      const options = {
        cancelableHandler: cancelHandler,
        stubs: { JobsTableTabs },
      };

      it('should display cancel all jobs button', async () => {
        createComponent({ ...options, provideOptions: { canUpdateAllJobs: true } });

        await waitForPromises();

        expect(findCancelJobsButton().exists()).toBe(true);
      });

      describe('when canUpdateAllJobs is false', () => {
        it('should not display cancel all jobs button', async () => {
          createComponent({ ...options, provideOptions: { canUpdateAllJobs: false } });

          await waitForPromises();

          expect(findCancelJobsButton().exists()).toBe(false);
        });
      });
    });

    describe('when there are no cancelable jobs', () => {
      it('should not display cancel all jobs button', async () => {
        createComponent({ provideOptions: { canUpdateAllJobs: true } });

        await waitForPromises();

        expect(findCancelJobsButton().exists()).toBe(false);
      });
    });
  });

  describe('filtered search', () => {
    it('should display filtered search', () => {
      createComponent();

      expect(findFilteredSearch().exists()).toBe(true);
    });

    // this test should be updated once BE supports tab and filtered search filtering
    // https://gitlab.com/gitlab-org/gitlab/-/issues/356210
    it.each`
      scope                                | shouldDisplay
      ${null}                              | ${true}
      ${['FAILED', 'SUCCESS', 'CANCELED']} | ${false}
    `(
      'with tab scope $scope the filtered search displays $shouldDisplay',
      async ({ scope, shouldDisplay }) => {
        createComponent();

        await waitForPromises();

        await findTabs().vm.$emit('fetchJobsByStatus', scope);

        expect(findFilteredSearch().exists()).toBe(shouldDisplay);
      },
    );

    describe.each`
      searchTokens                                          | expectedQueryParams
      ${[]}                                                 | ${{ runnerTypes: null, statuses: null }}
      ${[mockFailedSearchToken]}                            | ${{ runnerTypes: null, statuses: 'FAILED' }}
      ${[mockFailedSearchToken, mockSearchTokenRunnerType]} | ${{ runnerTypes: 'INSTANCE_TYPE', statuses: 'FAILED' }}
    `('when filtering jobs by searchTokens', ({ searchTokens, expectedQueryParams }) => {
      it(`refetches jobs query including filters ${JSON.stringify(
        expectedQueryParams,
      )}`, async () => {
        createComponent();

        expect(successHandler).toHaveBeenCalledTimes(1);

        await findFilteredSearch().vm.$emit('filterJobsBySearch', searchTokens);

        expect(successHandler).toHaveBeenCalledTimes(2);
        expect(successHandler).toHaveBeenNthCalledWith(2, { first: 50, ...expectedQueryParams });
      });

      it(`refetches jobs count query including filters ${JSON.stringify(
        expectedQueryParams,
      )}`, async () => {
        createComponent();

        expect(countSuccessHandler).toHaveBeenCalledTimes(1);

        await findFilteredSearch().vm.$emit('filterJobsBySearch', searchTokens);

        expect(countSuccessHandler).toHaveBeenCalledTimes(2);
        expect(countSuccessHandler).toHaveBeenNthCalledWith(2, expectedQueryParams);
      });
    });

    it('shows raw text warning when user inputs raw text', async () => {
      const expectedWarning = {
        message: RAW_TEXT_WARNING_ADMIN,
        type: 'warning',
      };

      createComponent();

      expect(successHandler).toHaveBeenCalledTimes(1);
      expect(countSuccessHandler).toHaveBeenCalledTimes(1);

      await findFilteredSearch().vm.$emit('filterJobsBySearch', ['raw text']);

      expect(createAlert).toHaveBeenCalledWith(expectedWarning);
      expect(successHandler).toHaveBeenCalledTimes(1);
      expect(countSuccessHandler).toHaveBeenCalledTimes(1);
    });

    it('updates URL query string when filtering jobs by status', async () => {
      createComponent();

      jest.spyOn(urlUtils, 'updateHistory');

      await findFilteredSearch().vm.$emit('filterJobsBySearch', [mockFailedSearchToken]);

      expect(urlUtils.updateHistory).toHaveBeenCalledWith({
        url: `${TEST_HOST}/?statuses=FAILED`,
      });
    });

    it('resets query param after clearing tokens', () => {
      createComponent();

      jest.spyOn(urlUtils, 'updateHistory');

      findFilteredSearch().vm.$emit('filterJobsBySearch', [mockFailedSearchToken]);

      expect(successHandler).toHaveBeenCalledWith({
        first: 50,
        statuses: 'FAILED',
        runnerTypes: null,
      });
      expect(urlUtils.updateHistory).toHaveBeenCalledWith({
        url: `${TEST_HOST}/?statuses=FAILED`,
      });

      findFilteredSearch().vm.$emit('filterJobsBySearch', []);

      expect(urlUtils.updateHistory).toHaveBeenCalledWith({
        url: `${TEST_HOST}/`,
      });

      expect(successHandler).toHaveBeenCalledWith({
        first: 50,
        statuses: null,
        runnerTypes: null,
      });
    });

    describe('when feature flag `adminJobsFilterRunnerType` is disabled', () => {
      const provideOptions = { glFeatures: { adminJobsFilterRunnerType: false } };

      describe.each`
        searchTokens                                          | expectedQueryParams
        ${[]}                                                 | ${{ statuses: null }}
        ${[mockFailedSearchToken]}                            | ${{ statuses: 'FAILED' }}
        ${[mockFailedSearchToken, mockSearchTokenRunnerType]} | ${{ statuses: 'FAILED' }}
      `('when filtering jobs by searchTokens', ({ searchTokens, expectedQueryParams }) => {
        it(`refetches jobs query including filters ${JSON.stringify(
          expectedQueryParams,
        )}`, async () => {
          createComponent({ provideOptions });

          expect(successHandler).toHaveBeenCalledTimes(1);

          await findFilteredSearch().vm.$emit('filterJobsBySearch', searchTokens);

          expect(successHandler).toHaveBeenCalledTimes(2);
          expect(successHandler).toHaveBeenNthCalledWith(2, { first: 50, ...expectedQueryParams });
        });

        it(`refetches jobs count query including filters ${JSON.stringify(
          expectedQueryParams,
        )}`, async () => {
          createComponent({ provideOptions });

          expect(countSuccessHandler).toHaveBeenCalledTimes(1);

          await findFilteredSearch().vm.$emit('filterJobsBySearch', searchTokens);

          expect(countSuccessHandler).toHaveBeenCalledTimes(2);
          expect(countSuccessHandler).toHaveBeenNthCalledWith(2, expectedQueryParams);
        });
      });
    });
  });
});
