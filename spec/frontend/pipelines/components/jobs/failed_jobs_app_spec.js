import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import FailedJobsApp from '~/pipelines/components/jobs/failed_jobs_app.vue';
import FailedJobsTable from '~/pipelines/components/jobs/failed_jobs_table.vue';
import GetFailedJobsQuery from '~/pipelines/graphql/queries/get_failed_jobs.query.graphql';
import { mockFailedJobsQueryResponse, mockFailedJobsSummaryData } from '../../mock_data';

Vue.use(VueApollo);

jest.mock('~/flash');

describe('Failed Jobs App', () => {
  let wrapper;
  let resolverSpy;

  const findLoadingSpinner = () => wrapper.findComponent(GlLoadingIcon);
  const findJobsTable = () => wrapper.findComponent(FailedJobsTable);

  const createMockApolloProvider = (resolver) => {
    const requestHandlers = [[GetFailedJobsQuery, resolver]];

    return createMockApollo(requestHandlers);
  };

  const createComponent = (resolver, failedJobsSummaryData = mockFailedJobsSummaryData) => {
    wrapper = shallowMount(FailedJobsApp, {
      provide: {
        fullPath: 'root/ci-project',
        pipelineIid: 1,
      },
      propsData: {
        failedJobsSummary: failedJobsSummaryData,
      },
      apolloProvider: createMockApolloProvider(resolver),
    });
  };

  beforeEach(() => {
    resolverSpy = jest.fn().mockResolvedValue(mockFailedJobsQueryResponse);
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('loading spinner', () => {
    it('displays loading spinner when fetching failed jobs', () => {
      createComponent(resolverSpy);

      expect(findLoadingSpinner().exists()).toBe(true);
    });

    it('hides loading spinner after the failed jobs have been fetched', async () => {
      createComponent(resolverSpy);

      await waitForPromises();

      expect(findLoadingSpinner().exists()).toBe(false);
    });
  });

  it('displays the failed jobs table', async () => {
    createComponent(resolverSpy);

    await waitForPromises();

    expect(findJobsTable().exists()).toBe(true);
    expect(createFlash).not.toHaveBeenCalled();
  });

  it('handles query fetch error correctly', async () => {
    resolverSpy = jest.fn().mockRejectedValue(new Error('GraphQL error'));

    createComponent(resolverSpy);

    await waitForPromises();

    expect(createFlash).toHaveBeenCalledWith({
      message: 'There was a problem fetching the failed jobs.',
    });
  });
});
