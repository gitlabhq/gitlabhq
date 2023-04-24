import { GlLoadingIcon, GlEmptyState, GlAlert } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import JobsTableTabs from '~/jobs/components/table/jobs_table_tabs.vue';
import JobsSkeletonLoader from '~/pages/admin/jobs/components/jobs_skeleton_loader.vue';
import getAllJobsQuery from '~/pages/admin/jobs/components/table/graphql/queries/get_all_jobs.query.graphql';
import getCancelableJobsQuery from '~/pages/admin/jobs/components/table/graphql/queries/get_cancelable_jobs_count.query.graphql';
import AdminJobsTableApp from '~/pages/admin/jobs/components/table/admin_jobs_table_app.vue';
import CancelJobs from '~/pages/admin/jobs/components/cancel_jobs.vue';
import JobsTable from '~/jobs/components/table/jobs_table.vue';

import {
  mockAllJobsResponsePaginated,
  mockJobsResponseEmpty,
  mockCancelableJobsCountResponse,
  statuses,
} from '../../../../../jobs/mock_data';

Vue.use(VueApollo);

describe('Job table app', () => {
  let wrapper;

  const successHandler = jest.fn().mockResolvedValue(mockAllJobsResponsePaginated);
  const emptyHandler = jest.fn().mockResolvedValue(mockJobsResponseEmpty);
  const failedHandler = jest.fn().mockRejectedValue(new Error('GraphQL error'));
  const cancelHandler = jest.fn().mockResolvedValue(mockCancelableJobsCountResponse);

  const findSkeletonLoader = () => wrapper.findComponent(JobsSkeletonLoader);
  const findLoadingSpinner = () => wrapper.findComponent(GlLoadingIcon);
  const findTable = () => wrapper.findComponent(JobsTable);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findTabs = () => wrapper.findComponent(JobsTableTabs);
  const findCancelJobsButton = () => wrapper.findComponent(CancelJobs);

  const createMockApolloProvider = (handler, cancelableHandler) => {
    const requestHandlers = [
      [getAllJobsQuery, handler],
      [getCancelableJobsQuery, cancelableHandler],
    ];

    return createMockApollo(requestHandlers);
  };

  const createComponent = ({
    handler = successHandler,
    cancelableHandler = cancelHandler,
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
      apolloProvider: createMockApolloProvider(handler, cancelableHandler),
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

      expect(findAlert().text()).toBe('There was an error fetching the jobs.');
      expect(findTable().exists()).toBe(false);
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
});
