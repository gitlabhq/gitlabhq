import { GlAlert, GlEmptyState, GlIntersectionObserver, GlLoadingIcon } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { s__ } from '~/locale';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { TEST_HOST } from 'spec/test_constants';
import { createAlert } from '~/alert';
import getJobsQuery from '~/ci/jobs_page/graphql/queries/get_jobs.query.graphql';
import getJobsCountQuery from '~/ci/jobs_page/graphql/queries/get_jobs_count.query.graphql';
import JobsTable from '~/ci/jobs_page/components/jobs_table.vue';
import JobsTableApp from '~/ci/jobs_page/jobs_page_app.vue';
import JobsTableTabs from '~/ci/jobs_page/components/jobs_table_tabs.vue';
import JobsFilteredSearch from '~/ci/common/private/jobs_filtered_search/app.vue';
import JobsSkeletonLoader from '~/ci/admin/jobs_table/components/jobs_skeleton_loader.vue';
import * as urlUtils from '~/lib/utils/url_utility';
import {
  mockJobsResponsePaginated,
  mockJobsResponseEmpty,
  mockFailedSearchToken,
  mockJobsCountResponse,
} from 'jest/ci/jobs_mock_data';

const projectPath = 'gitlab-org/gitlab';
Vue.use(VueApollo);

jest.mock('~/alert');

describe('Job table app', () => {
  let wrapper;

  const successHandler = jest.fn().mockResolvedValue(mockJobsResponsePaginated);
  const failedHandler = jest.fn().mockRejectedValue(new Error('GraphQL error'));
  const emptyHandler = jest.fn().mockResolvedValue(mockJobsResponseEmpty);

  const countSuccessHandler = jest.fn().mockResolvedValue(mockJobsCountResponse);

  const findSkeletonLoader = () => wrapper.findComponent(JobsSkeletonLoader);
  const findLoadingSpinner = () => wrapper.findComponent(GlLoadingIcon);
  const findTable = () => wrapper.findComponent(JobsTable);
  const findTabs = () => wrapper.findComponent(JobsTableTabs);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findFilteredSearch = () => wrapper.findComponent(JobsFilteredSearch);

  const triggerInfiniteScroll = () =>
    wrapper.findComponent(GlIntersectionObserver).vm.$emit('appear');

  const createMockApolloProvider = (handler, countHandler) => {
    const requestHandlers = [
      [getJobsQuery, handler],
      [getJobsCountQuery, countHandler],
    ];

    return createMockApollo(requestHandlers);
  };

  const createComponent = ({
    handler = successHandler,
    countHandler = countSuccessHandler,
    mountFn = shallowMount,
  } = {}) => {
    wrapper = mountFn(JobsTableApp, {
      provide: {
        fullPath: projectPath,
      },
      apolloProvider: createMockApolloProvider(handler, countHandler),
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

      expect(countSuccessHandler).toHaveBeenCalledTimes(2);

      // tab is switched to `finished`, no count
      await findTabs().vm.$emit('fetchJobsByStatus', ['FAILED', 'SUCCESS', 'CANCELED']);

      // tab is switched back to `all`, the old filter count has to be overwritten with new count
      await findTabs().vm.$emit('fetchJobsByStatus', null);

      expect(countSuccessHandler).toHaveBeenCalledTimes(3);
    });

    describe('when infinite scrolling is triggered', () => {
      it('does not display a skeleton loader', () => {
        triggerInfiniteScroll();

        expect(findSkeletonLoader().exists()).toBe(false);
      });

      it('handles infinite scrolling by calling fetch more', async () => {
        triggerInfiniteScroll();

        await nextTick();

        const pageSize = 30;

        expect(findLoadingSpinner().exists()).toBe(true);

        await waitForPromises();

        expect(findLoadingSpinner().exists()).toBe(false);

        expect(successHandler).toHaveBeenLastCalledWith({
          first: pageSize,
          fullPath: projectPath,
          after: mockJobsResponsePaginated.data.project.jobs.pageInfo.endCursor,
        });
      });
    });
  });

  describe('error state', () => {
    it('should show an alert if there is an error fetching the jobs data', async () => {
      createComponent({ handler: failedHandler });

      await waitForPromises();

      expect(findAlert().text()).toBe('There was an error fetching the jobs for your project.');
      expect(findTable().exists()).toBe(false);
    });

    it('should show an alert if there is an error fetching the jobs count data', async () => {
      createComponent({ handler: successHandler, countHandler: failedHandler });

      await waitForPromises();

      expect(findAlert().text()).toBe(
        'There was an error fetching the number of jobs for your project.',
      );
    });

    it('jobs table should still load if count query fails', async () => {
      createComponent({ handler: successHandler, countHandler: failedHandler });

      await waitForPromises();

      expect(findTable().exists()).toBe(true);
    });

    it('jobs count should be zero if count query fails', async () => {
      createComponent({ handler: successHandler, countHandler: failedHandler });

      await waitForPromises();

      expect(findTabs().props('allJobsCount')).toBe(0);
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

      expect(successHandler).toHaveBeenCalledTimes(1);

      await findFilteredSearch().vm.$emit('filterJobsBySearch', [mockFailedSearchToken]);

      expect(successHandler).toHaveBeenCalledTimes(2);
    });

    it('refetches jobs count query when filtering', async () => {
      createComponent();

      expect(countSuccessHandler).toHaveBeenCalledTimes(1);

      await findFilteredSearch().vm.$emit('filterJobsBySearch', [mockFailedSearchToken]);

      expect(countSuccessHandler).toHaveBeenCalledTimes(2);
    });

    it('shows raw text warning when user inputs raw text', async () => {
      const expectedWarning = {
        message: s__(
          'Jobs|Raw text search is not currently supported for the jobs filtered search feature. Please use the available search tokens.',
        ),
        variant: 'warning',
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
        first: 30,
        fullPath: 'gitlab-org/gitlab',
        statuses: 'FAILED',
      });
      expect(countSuccessHandler).toHaveBeenCalledWith({
        fullPath: 'gitlab-org/gitlab',
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
        first: 30,
        fullPath: 'gitlab-org/gitlab',
        statuses: null,
      });
      expect(countSuccessHandler).toHaveBeenCalledWith({
        fullPath: 'gitlab-org/gitlab',
        statuses: null,
      });
    });
  });
});
