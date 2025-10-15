import { GlAlert, GlEmptyState, GlKeysetPagination } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { TEST_HOST } from 'spec/test_constants';
import getJobsQuery from '~/ci/jobs_page/graphql/queries/get_jobs.query.graphql';
import getJobsCountQuery from '~/ci/jobs_page/graphql/queries/get_jobs_count.query.graphql';
import jobProcessedSubscription from '~/ci/jobs_page/graphql/subscriptions/ci_job_processed.subscription.graphql';
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
  mockPushSourceToken,
  mockBridgeKindToken,
  mockBuildKindToken,
} from 'jest/ci/jobs_mock_data';
import { DEFAULT_PAGINATION, JOBS_PER_PAGE } from '~/ci/jobs_page/constants';

const projectPath = 'gitlab-org/gitlab';
Vue.use(VueApollo);

const mockJobName = 'rspec-job';
const mockJobSource = mockPushSourceToken.value.data;

describe('Job table app', () => {
  let wrapper;

  const successHandler = jest.fn().mockResolvedValue(mockJobsResponsePaginated);
  const failedHandler = jest.fn().mockRejectedValue(new Error('GraphQL error'));
  const emptyHandler = jest.fn().mockResolvedValue(mockJobsResponseEmpty);
  const emptySubHandler = jest.fn().mockImplementation(() => {
    return new Promise(() => {});
  });

  const countSuccessHandler = jest.fn().mockResolvedValue(mockJobsCountResponse);

  const findSkeletonLoader = () => wrapper.findComponent(JobsSkeletonLoader);
  const findTable = () => wrapper.findComponent(JobsTable);
  const findTabs = () => wrapper.findComponent(JobsTableTabs);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findFilteredSearch = () => wrapper.findComponent(JobsFilteredSearch);
  const findPagination = () => wrapper.findComponent(GlKeysetPagination);

  const createMockApolloProvider = (handler, countHandler, subHandler) => {
    const requestHandlers = [
      [getJobsQuery, handler],
      [getJobsCountQuery, countHandler],
      [jobProcessedSubscription, subHandler],
    ];

    return createMockApollo(requestHandlers);
  };

  const createComponent = ({
    handler = successHandler,
    countHandler = countSuccessHandler,
    subHandler = emptySubHandler,
    mountFn = shallowMount,
    realtimeEnabled = true,
  } = {}) => {
    wrapper = mountFn(JobsTableApp, {
      provide: {
        fullPath: projectPath,
        glFeatures: {
          ciJobCreatedSubscription: realtimeEnabled,
        },
        projectId: '100',
      },
      apolloProvider: createMockApolloProvider(handler, countHandler, subHandler),
    });
  };

  describe('loading state', () => {
    it('should display skeleton loader when loading', () => {
      createComponent();

      expect(findSkeletonLoader().exists()).toBe(true);
      expect(findTable().exists()).toBe(false);
    });

    it('when switching tabs only the skeleton loader should show', () => {
      createComponent();

      findTabs().vm.$emit('fetchJobsByStatus', null);

      expect(findSkeletonLoader().exists()).toBe(true);
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
  });

  describe('error state', () => {
    it('should show an alert if there is an error fetching the jobs data', async () => {
      createComponent({ handler: failedHandler, mountFn: mount });

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

    it('filters jobs by status', async () => {
      createComponent();

      await findFilteredSearch().vm.$emit('filterJobsBySearch', [mockFailedSearchToken]);

      expect(successHandler).toHaveBeenCalledWith({
        fullPath: 'gitlab-org/gitlab',
        statuses: 'FAILED',
        sources: null,
        name: null,
        kind: 'BUILD',
        ...DEFAULT_PAGINATION,
      });
      expect(countSuccessHandler).toHaveBeenCalledWith({
        fullPath: 'gitlab-org/gitlab',
        statuses: 'FAILED',
        sources: null,
        name: null,
        kind: 'BUILD',
      });
    });

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

    it('filters jobs by name when user inputs raw text', async () => {
      createComponent();

      await findFilteredSearch().vm.$emit('filterJobsBySearch', ['rspec-job']);

      expect(successHandler).toHaveBeenCalledWith({
        fullPath: 'gitlab-org/gitlab',
        name: 'rspec-job',
        statuses: null,
        sources: null,
        kind: 'BUILD',
        ...DEFAULT_PAGINATION,
      });
    });

    it('updates URL query string when filtering jobs by status', async () => {
      createComponent();

      jest.spyOn(urlUtils, 'updateHistory');

      await findFilteredSearch().vm.$emit('filterJobsBySearch', [mockFailedSearchToken]);

      expect(urlUtils.updateHistory).toHaveBeenCalledWith({
        url: `${TEST_HOST}/?statuses=FAILED&kind=BUILD`,
      });
    });

    it('resets query param after clearing tokens', () => {
      createComponent();

      jest.spyOn(urlUtils, 'updateHistory');

      findFilteredSearch().vm.$emit('filterJobsBySearch', [
        mockFailedSearchToken,
        mockPushSourceToken,
      ]);

      expect(successHandler).toHaveBeenCalledWith({
        fullPath: 'gitlab-org/gitlab',
        statuses: 'FAILED',
        sources: mockJobSource,
        name: null,
        kind: 'BUILD',
        ...DEFAULT_PAGINATION,
      });
      expect(countSuccessHandler).toHaveBeenCalledWith({
        fullPath: 'gitlab-org/gitlab',
        statuses: 'FAILED',
        sources: mockJobSource,
        name: null,
        kind: 'BUILD',
      });
      expect(urlUtils.updateHistory).toHaveBeenCalledWith({
        url: `${TEST_HOST}/?statuses=FAILED&sources=${mockJobSource}&kind=BUILD`,
      });

      findFilteredSearch().vm.$emit('filterJobsBySearch', []);

      expect(urlUtils.updateHistory).toHaveBeenCalledWith({
        url: `${TEST_HOST}/?kind=BUILD`,
      });

      expect(successHandler).toHaveBeenCalledWith({
        fullPath: 'gitlab-org/gitlab',
        statuses: null,
        sources: null,
        name: null,
        kind: 'BUILD',
        ...DEFAULT_PAGINATION,
      });
      expect(countSuccessHandler).toHaveBeenCalledWith({
        fullPath: 'gitlab-org/gitlab',
        statuses: null,
        sources: null,
        name: null,
        kind: 'BUILD',
      });
    });

    it('filters jobs by source', async () => {
      createComponent();

      await findFilteredSearch().vm.$emit('filterJobsBySearch', [mockPushSourceToken]);

      expect(successHandler).toHaveBeenCalledWith({
        fullPath: 'gitlab-org/gitlab',
        sources: mockJobSource,
        statuses: null,
        name: null,
        kind: 'BUILD',
        ...DEFAULT_PAGINATION,
      });
      expect(countSuccessHandler).toHaveBeenCalledWith({
        fullPath: 'gitlab-org/gitlab',
        sources: mockJobSource,
        statuses: null,
        name: null,
        kind: 'BUILD',
      });
    });

    it('filters only by source after removing status filter', async () => {
      createComponent();

      await findFilteredSearch().vm.$emit('filterJobsBySearch', [
        mockFailedSearchToken,
        mockPushSourceToken,
      ]);

      expect(successHandler).toHaveBeenCalledWith({
        fullPath: 'gitlab-org/gitlab',
        sources: mockJobSource,
        statuses: 'FAILED',
        name: null,
        kind: 'BUILD',
        ...DEFAULT_PAGINATION,
      });
      expect(countSuccessHandler).toHaveBeenCalledWith({
        fullPath: 'gitlab-org/gitlab',
        sources: mockJobSource,
        statuses: 'FAILED',
        name: null,
        kind: 'BUILD',
      });

      await findFilteredSearch().vm.$emit('filterJobsBySearch', [mockPushSourceToken]);

      expect(successHandler).toHaveBeenCalledWith({
        fullPath: 'gitlab-org/gitlab',
        sources: mockJobSource,
        statuses: null,
        name: null,
        kind: 'BUILD',
        ...DEFAULT_PAGINATION,
      });
      expect(countSuccessHandler).toHaveBeenCalledWith({
        fullPath: 'gitlab-org/gitlab',
        sources: mockJobSource,
        statuses: null,
        name: null,
        kind: 'BUILD',
      });
    });

    it('updates URL query string when filtering jobs by source', async () => {
      createComponent();

      jest.spyOn(urlUtils, 'updateHistory');

      await findFilteredSearch().vm.$emit('filterJobsBySearch', [mockPushSourceToken]);

      expect(urlUtils.updateHistory).toHaveBeenCalledWith({
        url: `${TEST_HOST}/?sources=${mockJobSource}&kind=BUILD`,
      });
    });

    it('updates URL query string when filtering jobs by source and status', async () => {
      createComponent();

      jest.spyOn(urlUtils, 'updateHistory');

      await findFilteredSearch().vm.$emit('filterJobsBySearch', [
        mockFailedSearchToken,
        mockPushSourceToken,
      ]);

      expect(urlUtils.updateHistory).toHaveBeenCalledWith({
        url: `${TEST_HOST}/?statuses=FAILED&sources=${mockJobSource}&kind=BUILD`,
      });
    });

    describe('job name filtering', () => {
      beforeEach(() => {
        createComponent();
      });

      it('filters jobs by name', async () => {
        await findFilteredSearch().vm.$emit('filterJobsBySearch', [mockJobName]);

        expect(successHandler).toHaveBeenCalledWith({
          fullPath: 'gitlab-org/gitlab',
          name: mockJobName,
          statuses: null,
          sources: null,
          kind: 'BUILD',
          ...DEFAULT_PAGINATION,
        });
        expect(countSuccessHandler).toHaveBeenCalledWith({
          fullPath: 'gitlab-org/gitlab',
          name: mockJobName,
          statuses: null,
          sources: null,
          kind: 'BUILD',
        });
      });

      it('filters only by name after removing status filter', async () => {
        await findFilteredSearch().vm.$emit('filterJobsBySearch', [
          mockFailedSearchToken,
          mockJobName,
        ]);

        expect(successHandler).toHaveBeenCalledWith({
          fullPath: 'gitlab-org/gitlab',
          name: mockJobName,
          statuses: 'FAILED',
          sources: null,
          kind: 'BUILD',
          ...DEFAULT_PAGINATION,
        });
        expect(countSuccessHandler).toHaveBeenCalledWith({
          fullPath: 'gitlab-org/gitlab',
          name: mockJobName,
          statuses: 'FAILED',
          sources: null,
          kind: 'BUILD',
        });

        await findFilteredSearch().vm.$emit('filterJobsBySearch', [mockJobName]);

        expect(successHandler).toHaveBeenCalledWith({
          fullPath: 'gitlab-org/gitlab',
          name: mockJobName,
          statuses: null,
          sources: null,
          kind: 'BUILD',
          ...DEFAULT_PAGINATION,
        });
        expect(countSuccessHandler).toHaveBeenCalledWith({
          fullPath: 'gitlab-org/gitlab',
          name: mockJobName,
          statuses: null,
          sources: null,
          kind: 'BUILD',
        });
      });

      it('updates URL query string when filtering jobs by name', async () => {
        jest.spyOn(urlUtils, 'updateHistory');

        await findFilteredSearch().vm.$emit('filterJobsBySearch', [mockJobName]);

        expect(urlUtils.updateHistory).toHaveBeenCalledWith({
          url: `${TEST_HOST}/?name=${mockJobName}&kind=BUILD`,
        });
      });

      it('updates URL query string when filtering jobs by name and status', async () => {
        jest.spyOn(urlUtils, 'updateHistory');

        await findFilteredSearch().vm.$emit('filterJobsBySearch', [
          mockFailedSearchToken,
          mockJobName,
        ]);

        expect(urlUtils.updateHistory).toHaveBeenCalledWith({
          url: `${TEST_HOST}/?statuses=FAILED&name=${mockJobName}&kind=BUILD`,
        });
      });

      it('resets query param after clearing tokens', () => {
        jest.spyOn(urlUtils, 'updateHistory');

        findFilteredSearch().vm.$emit('filterJobsBySearch', [mockFailedSearchToken, mockJobName]);

        expect(successHandler).toHaveBeenCalledWith({
          fullPath: 'gitlab-org/gitlab',
          statuses: 'FAILED',
          sources: null,
          name: mockJobName,
          kind: 'BUILD',
          ...DEFAULT_PAGINATION,
        });
        expect(countSuccessHandler).toHaveBeenCalledWith({
          fullPath: 'gitlab-org/gitlab',
          statuses: 'FAILED',
          sources: null,
          name: mockJobName,
          kind: 'BUILD',
        });
        expect(urlUtils.updateHistory).toHaveBeenCalledWith({
          url: `${TEST_HOST}/?statuses=FAILED&name=${mockJobName}&kind=BUILD`,
        });

        findFilteredSearch().vm.$emit('filterJobsBySearch', []);

        expect(urlUtils.updateHistory).toHaveBeenCalledWith({
          url: `${TEST_HOST}/?kind=BUILD`,
        });

        expect(successHandler).toHaveBeenCalledWith({
          fullPath: 'gitlab-org/gitlab',
          statuses: null,
          sources: null,
          name: null,
          kind: 'BUILD',
          ...DEFAULT_PAGINATION,
        });
        expect(countSuccessHandler).toHaveBeenCalledWith({
          fullPath: 'gitlab-org/gitlab',
          statuses: null,
          sources: null,
          name: null,
          kind: 'BUILD',
        });
      });
    });

    describe('filters jobs by kind', () => {
      beforeEach(async () => {
        createComponent();

        successHandler.mockClear();
        countSuccessHandler.mockClear();

        await waitForPromises();
      });

      it('filters trigger jobs', async () => {
        jest.spyOn(urlUtils, 'updateHistory');

        await findFilteredSearch().vm.$emit('filterJobsBySearch', [mockBridgeKindToken]);

        expect(successHandler).toHaveBeenCalledWith({
          fullPath: 'gitlab-org/gitlab',
          statuses: null,
          sources: null,
          name: null,
          kind: 'BRIDGE',
          ...DEFAULT_PAGINATION,
        });
        expect(countSuccessHandler).toHaveBeenCalledWith({
          fullPath: 'gitlab-org/gitlab',
          statuses: null,
          sources: null,
          name: null,
          kind: 'BRIDGE',
        });
        expect(urlUtils.updateHistory).toHaveBeenCalledWith({
          url: `${TEST_HOST}/?kind=BRIDGE`,
        });
      });

      it('filters build jobs', async () => {
        jest.spyOn(urlUtils, 'updateHistory');

        await findFilteredSearch().vm.$emit('filterJobsBySearch', [mockBuildKindToken]);

        expect(successHandler).toHaveBeenCalledWith({
          fullPath: 'gitlab-org/gitlab',
          statuses: null,
          sources: null,
          name: null,
          kind: 'BUILD',
          ...DEFAULT_PAGINATION,
        });
        expect(countSuccessHandler).toHaveBeenCalledWith({
          fullPath: 'gitlab-org/gitlab',
          statuses: null,
          sources: null,
          name: null,
          kind: 'BUILD',
        });
        expect(urlUtils.updateHistory).toHaveBeenCalledWith({
          url: `${TEST_HOST}/?kind=BUILD`,
        });
      });
    });
  });

  describe('pagination', () => {
    it('displays keyset pagination', async () => {
      createComponent();

      await waitForPromises();

      expect(findPagination().exists()).toBe(true);
    });

    it('binds page info', async () => {
      createComponent();

      await waitForPromises();

      const { pageInfo } = mockJobsResponsePaginated.data.project.jobs;

      expect(findPagination().props()).toEqual(
        expect.objectContaining({
          endCursor: pageInfo.endCursor,
          hasNextPage: pageInfo.hasNextPage,
          hasPreviousPage: pageInfo.hasPreviousPage,
          startCursor: pageInfo.startCursor,
        }),
      );
    });

    it('calls next event correctly', async () => {
      createComponent();

      await waitForPromises();

      expect(successHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          first: JOBS_PER_PAGE,
          fullPath: 'gitlab-org/gitlab',
        }),
      );

      findPagination().vm.$emit('next');

      await waitForPromises();

      const { pageInfo } = mockJobsResponsePaginated.data.project.jobs;

      expect(successHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          after: pageInfo.endCursor,
          before: null,
          first: JOBS_PER_PAGE,
          fullPath: 'gitlab-org/gitlab',
          last: null,
        }),
      );
    });

    it('calls prev event correctly', async () => {
      createComponent();

      await waitForPromises();

      expect(successHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          first: JOBS_PER_PAGE,
          fullPath: 'gitlab-org/gitlab',
        }),
      );

      findPagination().vm.$emit('prev');

      await waitForPromises();

      const { pageInfo } = mockJobsResponsePaginated.data.project.jobs;

      expect(successHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          after: null,
          before: pageInfo.startCursor,
          first: null,
          fullPath: 'gitlab-org/gitlab',
          last: JOBS_PER_PAGE,
        }),
      );
    });

    it('resets pagination after filtering jobs by search', async () => {
      createComponent();

      await waitForPromises();

      findPagination().vm.$emit('next');

      await waitForPromises();

      await findFilteredSearch().vm.$emit('filterJobsBySearch', [mockFailedSearchToken]);

      expect(successHandler).toHaveBeenCalledWith({
        fullPath: 'gitlab-org/gitlab',
        statuses: 'FAILED',
        sources: null,
        name: null,
        kind: 'BUILD',
        ...DEFAULT_PAGINATION,
      });
    });

    it('resets pagination after filtering jobs by status tabs', async () => {
      createComponent();

      await waitForPromises();

      findPagination().vm.$emit('next');

      await waitForPromises();

      await findTabs().vm.$emit('fetchJobsByStatus', ['FAILED', 'SUCCESS', 'CANCELED']);

      expect(successHandler).toHaveBeenCalledWith({
        fullPath: 'gitlab-org/gitlab',
        statuses: ['FAILED', 'SUCCESS', 'CANCELED'],
        kind: 'BUILD',
        ...DEFAULT_PAGINATION,
      });
    });
  });

  describe('subscription', () => {
    it('calls subscription with correct variables', async () => {
      createComponent();

      await waitForPromises();

      expect(emptySubHandler).toHaveBeenCalledWith({ projectId: 'gid://gitlab/Project/100' });
    });

    it('does not make redundant subscription calls', async () => {
      createComponent();

      await waitForPromises();

      expect(emptySubHandler).toHaveBeenCalledTimes(1);
    });

    describe('with the feature flag turned off', () => {
      it('does not call the subscription', async () => {
        createComponent({ realtimeEnabled: false });

        await waitForPromises();

        expect(emptySubHandler).not.toHaveBeenCalled();
      });
    });
  });
});
