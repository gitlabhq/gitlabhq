import { GlSkeletonLoader, GlAlert, GlEmptyState, GlPagination } from '@gitlab/ui';
import { createLocalVue, mount, shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import getJobsQuery from '~/jobs/components/table/graphql/queries/get_jobs.query.graphql';
import JobsTable from '~/jobs/components/table/jobs_table.vue';
import JobsTableApp from '~/jobs/components/table/jobs_table_app.vue';
import JobsTableTabs from '~/jobs/components/table/jobs_table_tabs.vue';
import { mockJobsQueryResponse, mockJobsQueryEmptyResponse } from '../../mock_data';

const projectPath = 'gitlab-org/gitlab';
const localVue = createLocalVue();
localVue.use(VueApollo);

describe('Job table app', () => {
  let wrapper;

  const successHandler = jest.fn().mockResolvedValue(mockJobsQueryResponse);
  const failedHandler = jest.fn().mockRejectedValue(new Error('GraphQL error'));
  const emptyHandler = jest.fn().mockResolvedValue(mockJobsQueryEmptyResponse);

  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findTable = () => wrapper.findComponent(JobsTable);
  const findTabs = () => wrapper.findComponent(JobsTableTabs);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findPagination = () => wrapper.findComponent(GlPagination);

  const findPrevious = () => findPagination().findAll('.page-item').at(0);
  const findNext = () => findPagination().findAll('.page-item').at(1);

  const createMockApolloProvider = (handler) => {
    const requestHandlers = [[getJobsQuery, handler]];

    return createMockApollo(requestHandlers);
  };

  const createComponent = ({
    handler = successHandler,
    mountFn = shallowMount,
    data = {},
  } = {}) => {
    wrapper = mountFn(JobsTableApp, {
      data() {
        return {
          ...data,
        };
      },
      provide: {
        projectPath,
      },
      localVue,
      apolloProvider: createMockApolloProvider(handler),
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('loading state', () => {
    it('should display skeleton loader when loading', () => {
      createComponent();

      expect(findSkeletonLoader().exists()).toBe(true);
      expect(findTable().exists()).toBe(false);
      expect(findPagination().exists()).toBe(false);
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
      expect(findPagination().exists()).toBe(true);
    });

    it('should refetch jobs query on fetchJobsByStatus event', async () => {
      jest.spyOn(wrapper.vm.$apollo.queries.jobs, 'refetch').mockImplementation(jest.fn());

      expect(wrapper.vm.$apollo.queries.jobs.refetch).toHaveBeenCalledTimes(0);

      await findTabs().vm.$emit('fetchJobsByStatus');

      expect(wrapper.vm.$apollo.queries.jobs.refetch).toHaveBeenCalledTimes(1);
    });
  });

  describe('pagination', () => {
    it('should disable the next page button on the last page', async () => {
      createComponent({
        handler: successHandler,
        mountFn: mount,
        data: {
          pagination: {
            currentPage: 3,
          },
          jobs: {
            pageInfo: {
              hasPreviousPage: true,
              startCursor: 'abc',
              endCursor: 'bcd',
            },
          },
        },
      });

      await wrapper.vm.$nextTick();

      wrapper.setData({
        jobs: {
          pageInfo: {
            hasNextPage: false,
          },
        },
      });

      await wrapper.vm.$nextTick();

      expect(findPrevious().exists()).toBe(true);
      expect(findNext().exists()).toBe(true);
      expect(findNext().classes('disabled')).toBe(true);
    });

    it('should disable the previous page button on the first page', async () => {
      createComponent({
        handler: successHandler,
        mountFn: mount,
        data: {
          pagination: {
            currentPage: 1,
          },
          jobs: {
            pageInfo: {
              hasNextPage: true,
              hasPreviousPage: false,
              startCursor: 'abc',
              endCursor: 'bcd',
            },
          },
        },
      });

      await wrapper.vm.$nextTick();

      expect(findPrevious().exists()).toBe(true);
      expect(findPrevious().classes('disabled')).toBe(true);
      expect(findNext().exists()).toBe(true);
    });
  });

  describe('error state', () => {
    it('should show an alert if there is an error fetching the data', async () => {
      createComponent({ handler: failedHandler });

      await waitForPromises();

      expect(findAlert().exists()).toBe(true);
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
});
