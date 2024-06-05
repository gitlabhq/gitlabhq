import { GlIntersectionObserver, GlSkeletonLoader, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import JobsApp from '~/ci/pipeline_details/jobs/jobs_app.vue';
import JobsTable from '~/ci/jobs_page/components/jobs_table.vue';
import getPipelineJobsQuery from '~/ci/pipeline_details/jobs/graphql/queries/get_pipeline_jobs.query.graphql';
import { POLL_INTERVAL } from '~/ci/pipeline_details/graph/constants';
import { mockPipelineJobsQueryResponse } from '../mock_data';

Vue.use(VueApollo);

jest.mock('~/alert');

describe('Jobs app', () => {
  let wrapper;
  let resolverSpy;

  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findLoadingSpinner = () => wrapper.findComponent(GlLoadingIcon);
  const findJobsTable = () => wrapper.findComponent(JobsTable);

  const triggerInfiniteScroll = () =>
    wrapper.findComponent(GlIntersectionObserver).vm.$emit('appear');

  const createMockApolloProvider = (resolver) => {
    const requestHandlers = [[getPipelineJobsQuery, resolver]];

    return createMockApollo(requestHandlers);
  };

  const graphqlResourceEtag = '/api/graphql:pipelines/id/1';

  const createComponent = (resolver) => {
    wrapper = shallowMount(JobsApp, {
      provide: {
        projectPath: 'root/ci-project',
        pipelineIid: 1,
        graphqlResourceEtag,
      },
      apolloProvider: createMockApolloProvider(resolver),
    });
  };

  beforeEach(() => {
    resolverSpy = jest.fn().mockResolvedValue(mockPipelineJobsQueryResponse);
  });

  describe('loading spinner', () => {
    const setup = async () => {
      createComponent(resolverSpy);

      await waitForPromises();

      triggerInfiniteScroll();
    };

    it('displays loading spinner when fetching more jobs', async () => {
      await setup();

      expect(findLoadingSpinner().exists()).toBe(true);
      expect(findSkeletonLoader().exists()).toBe(false);
    });

    it('hides loading spinner after jobs have been fetched', async () => {
      await setup();
      await waitForPromises();

      expect(findLoadingSpinner().exists()).toBe(false);
      expect(findSkeletonLoader().exists()).toBe(false);
    });
  });

  it('displays the skeleton loader', () => {
    createComponent(resolverSpy);

    expect(findSkeletonLoader().exists()).toBe(true);
    expect(findJobsTable().exists()).toBe(false);
  });

  it('displays the jobs table', async () => {
    createComponent(resolverSpy);

    await waitForPromises();

    expect(findJobsTable().exists()).toBe(true);
    expect(findSkeletonLoader().exists()).toBe(false);
    expect(createAlert).not.toHaveBeenCalled();
  });

  it('handles job fetch error correctly', async () => {
    resolverSpy = jest.fn().mockRejectedValue(new Error('GraphQL error'));

    createComponent(resolverSpy);

    await waitForPromises();

    expect(createAlert).toHaveBeenCalledWith({
      message: 'An error occurred while fetching the pipelines jobs.',
    });
  });

  it('handles infinite scrolling by calling fetchMore', async () => {
    createComponent(resolverSpy);
    await waitForPromises();

    triggerInfiniteScroll();
    await waitForPromises();

    expect(resolverSpy).toHaveBeenCalledWith({
      after: 'eyJpZCI6Ijg0NyJ9',
      fullPath: 'root/ci-project',
      iid: 1,
    });
  });

  it('does not display skeleton loader again after fetchMore', async () => {
    createComponent(resolverSpy);

    expect(findSkeletonLoader().exists()).toBe(true);
    await waitForPromises();

    triggerInfiniteScroll();
    await waitForPromises();

    expect(findSkeletonLoader().exists()).toBe(false);
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
