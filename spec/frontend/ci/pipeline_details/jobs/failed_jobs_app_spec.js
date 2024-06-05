import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import FailedJobsApp from '~/ci/pipeline_details/jobs/failed_jobs_app.vue';
import FailedJobsTable from '~/ci/pipeline_details/jobs/components/failed_jobs_table.vue';
import GetFailedJobsQuery from '~/ci/pipeline_details/jobs/graphql/queries/get_failed_jobs.query.graphql';
import { POLL_INTERVAL } from '~/ci/pipeline_details/graph/constants';
import { mockFailedJobsQueryResponse } from 'jest/ci/pipeline_details/mock_data';

Vue.use(VueApollo);

jest.mock('~/alert');

describe('Failed Jobs App', () => {
  let wrapper;
  let resolverSpy;

  const findLoadingSpinner = () => wrapper.findComponent(GlLoadingIcon);
  const findJobsTable = () => wrapper.findComponent(FailedJobsTable);

  const createMockApolloProvider = (resolver) => {
    const requestHandlers = [[GetFailedJobsQuery, resolver]];

    return createMockApollo(requestHandlers);
  };

  const graphqlResourceEtag = '/api/graphql:pipelines/id/1';

  const createComponent = (resolver) => {
    wrapper = shallowMount(FailedJobsApp, {
      provide: {
        fullPath: 'root/ci-project',
        pipelineIid: 1,
        graphqlResourceEtag,
      },
      apolloProvider: createMockApolloProvider(resolver),
    });
  };

  beforeEach(() => {
    resolverSpy = jest.fn().mockResolvedValue(mockFailedJobsQueryResponse);
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
    expect(createAlert).not.toHaveBeenCalled();
  });

  it('handles query fetch error correctly', async () => {
    resolverSpy = jest.fn().mockRejectedValue(new Error('GraphQL error'));

    createComponent(resolverSpy);

    await waitForPromises();

    expect(createAlert).toHaveBeenCalledWith({
      message: 'There was a problem fetching the failed jobs.',
    });
  });

  describe('polling', () => {
    beforeEach(() => {
      createComponent(resolverSpy);
    });

    it('polls for query data', () => {
      expect(resolverSpy).toHaveBeenCalledTimes(1);

      jest.advanceTimersByTime(POLL_INTERVAL);

      expect(resolverSpy).toHaveBeenCalledTimes(2);
    });
  });
});
