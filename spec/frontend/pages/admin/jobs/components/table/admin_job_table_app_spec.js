import { GlLoadingIcon, GlEmptyState, GlAlert, GlIntersectionObserver } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import JobsTableTabs from '~/jobs/components/table/jobs_table_tabs.vue';
import JobsSkeletonLoader from '~/pages/admin/jobs/components/jobs_skeleton_loader.vue';
import getAllJobsQuery from '~/pages/admin/jobs/components/table/graphql/queries/get_all_jobs.query.graphql';
import getAllJobsCount from '~/pages/admin/jobs/components/table/graphql/queries/get_all_jobs_count.query.graphql';
import getCancelableJobsQuery from '~/pages/admin/jobs/components/table/graphql/queries/get_cancelable_jobs_count.query.graphql';
import AdminJobsTableApp from '~/pages/admin/jobs/components/table/admin_jobs_table_app.vue';
import CancelJobs from '~/pages/admin/jobs/components/cancel_jobs.vue';
import JobsTable from '~/jobs/components/table/jobs_table.vue';
import { createAlert } from '~/alert';
import { TEST_HOST } from 'spec/test_constants';
import JobsFilteredSearch from '~/jobs/components/filtered_search/jobs_filtered_search.vue';
import * as urlUtils from '~/lib/utils/url_utility';
import {
  JOBS_FETCH_ERROR_MSG,
  CANCELABLE_JOBS_ERROR_MSG,
  LOADING_ARIA_LABEL,
  RAW_TEXT_WARNING_ADMIN,
  JOBS_COUNT_ERROR_MESSAGE,
} from '~/pages/admin/jobs/components/constants';
import {
  mockAllJobsResponsePaginated,
  mockCancelableJobsCountResponse,
  mockAllJobsResponseEmpty,
  statuses,
  mockFailedSearchToken,
  mockAllJobsCountResponse,
} from '../../../../../jobs/mock_data';

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
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findTabs = () => wrapper.findComponent(JobsTableTabs);
  const findCancelJobsButton = () => wrapper.findComponent(CancelJobs);
  const findFilteredSearch = () => wrapper.findComponent(JobsFilteredSearch);

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
    mountFn = shallowMount,
    data = {},
  } = {}) => {
    wrapper = mountFn(AdminJobsTableApp, {
      data() {
        return {
          ...data,
        };
      },
      provide: {
        jobStatuses: statuses,
      },
      apolloProvider: createMockApolloProvider(handler, cancelableHandler, countHandler),
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
      jest.spyOn(wrapper.vm.$apollo.queries.jobs, 'refetch').mockImplementation(jest.fn());

      expect(wrapper.vm.$apollo.queries.jobs.refetch).toHaveBeenCalledTimes(0);

      await findTabs().vm.$emit('fetchJobsByStatus');

      expect(wrapper.vm.$apollo.queries.jobs.refetch).toHaveBeenCalledTimes(1);
    });

    it('avoids refetch jobs query when scope has not changed', async () => {
      jest.spyOn(wrapper.vm.$apollo.queries.jobs, 'refetch').mockImplementation(jest.fn());

      expect(wrapper.vm.$apollo.queries.jobs.refetch).toHaveBeenCalledTimes(0);

      await findTabs().vm.$emit('fetchJobsByStatus', null);

      expect(wrapper.vm.$apollo.queries.jobs.refetch).toHaveBeenCalledTimes(0);
    });

    it('should refetch jobs count query when the amount jobs and count do not match', async () => {
      jest.spyOn(wrapper.vm.$apollo.queries.jobsCount, 'refetch').mockImplementation(jest.fn());

      expect(wrapper.vm.$apollo.queries.jobsCount.refetch).toHaveBeenCalledTimes(0);

      // after applying filter a new count is fetched
      findFilteredSearch().vm.$emit('filterJobsBySearch', [mockFailedSearchToken]);

      expect(wrapper.vm.$apollo.queries.jobsCount.refetch).toHaveBeenCalledTimes(1);

      // tab is switched to `finished`, no count
      await findTabs().vm.$emit('fetchJobsByStatus', ['FAILED', 'SUCCESS', 'CANCELED']);

      // tab is switched back to `all`, the old filter count has to be overwritten with new count
      await findTabs().vm.$emit('fetchJobsByStatus', null);

      expect(wrapper.vm.$apollo.queries.jobsCount.refetch).toHaveBeenCalledTimes(2);
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
      createComponent({ handler: emptyHandler, mountFn: mount });

      await waitForPromises();

      expect(findEmptyState().exists()).toBe(true);
      expect(findTable().exists()).toBe(false);
    });

    it('should not display empty state if there are jobs and tab scope is not null', async () => {
      createComponent({ handler: successHandler, mountFn: mount });

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
    it('should display cancel all jobs button', async () => {
      createComponent({ cancelableHandler: cancelHandler, mountFn: mount });

      await waitForPromises();

      expect(findCancelJobsButton().exists()).toBe(true);
    });

    it('should not display cancel all jobs button', async () => {
      createComponent();

      await waitForPromises();

      expect(findCancelJobsButton().exists()).toBe(false);
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

    it('refetches jobs query when filtering', async () => {
      createComponent();

      jest.spyOn(wrapper.vm.$apollo.queries.jobs, 'refetch').mockImplementation(jest.fn());

      expect(wrapper.vm.$apollo.queries.jobs.refetch).toHaveBeenCalledTimes(0);

      await findFilteredSearch().vm.$emit('filterJobsBySearch', [mockFailedSearchToken]);

      expect(wrapper.vm.$apollo.queries.jobs.refetch).toHaveBeenCalledTimes(1);
    });

    it('refetches jobs count query when filtering', async () => {
      createComponent();

      jest.spyOn(wrapper.vm.$apollo.queries.jobsCount, 'refetch').mockImplementation(jest.fn());

      expect(wrapper.vm.$apollo.queries.jobsCount.refetch).toHaveBeenCalledTimes(0);

      await findFilteredSearch().vm.$emit('filterJobsBySearch', [mockFailedSearchToken]);

      expect(wrapper.vm.$apollo.queries.jobsCount.refetch).toHaveBeenCalledTimes(1);
    });

    it('shows raw text warning when user inputs raw text', async () => {
      const expectedWarning = {
        message: RAW_TEXT_WARNING_ADMIN,
        type: 'warning',
      };

      createComponent();

      jest.spyOn(wrapper.vm.$apollo.queries.jobs, 'refetch').mockImplementation(jest.fn());
      jest.spyOn(wrapper.vm.$apollo.queries.jobsCount, 'refetch').mockImplementation(jest.fn());

      await findFilteredSearch().vm.$emit('filterJobsBySearch', ['raw text']);

      expect(createAlert).toHaveBeenCalledWith(expectedWarning);
      expect(wrapper.vm.$apollo.queries.jobs.refetch).toHaveBeenCalledTimes(0);
      expect(wrapper.vm.$apollo.queries.jobsCount.refetch).toHaveBeenCalledTimes(0);
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
      });
    });
  });
});
