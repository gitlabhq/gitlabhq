import { GlSkeletonLoader, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import JobsTable from '~/jobs/components/table/jobs_table.vue';
import getJobsQuery from '~/pages/admin/jobs/components/table/graphql/queries/get_all_jobs.query.graphql';
import AdminJobsTableApp from '~/pages/admin/jobs/components/table/admin_jobs_table_app.vue';

import { mockAllJobsResponsePaginated, statuses } from '../../../../../jobs/mock_data';

Vue.use(VueApollo);

describe('Job table app', () => {
  let wrapper;

  const successHandler = jest.fn().mockResolvedValue(mockAllJobsResponsePaginated);

  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findLoadingSpinner = () => wrapper.findComponent(GlLoadingIcon);
  const findTable = () => wrapper.findComponent(JobsTable);

  const createMockApolloProvider = (handler) => {
    const requestHandlers = [[getJobsQuery, handler]];

    return createMockApollo(requestHandlers);
  };

  const createComponent = ({
    handler = successHandler,
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
      apolloProvider: createMockApolloProvider(handler),
    });
  };

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
  });
});
