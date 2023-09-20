import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import CommitBoxPipelineMiniGraph from '~/projects/commit_box/info/components/commit_box_pipeline_mini_graph.vue';
import PipelineMiniGraph from '~/ci/pipeline_mini_graph/pipeline_mini_graph.vue';
import LegacyPipelineMiniGraph from '~/ci/pipeline_mini_graph/legacy_pipeline_mini_graph.vue';
import { COMMIT_BOX_POLL_INTERVAL } from '~/projects/commit_box/info/constants';
import getLinkedPipelinesQuery from '~/ci/pipeline_details/graphql/queries/get_linked_pipelines.query.graphql';
import getPipelineStagesQuery from '~/ci/pipeline_mini_graph/graphql/queries/get_pipeline_stages.query.graphql';
import * as sharedGraphQlUtils from '~/graphql_shared/utils';
import {
  mockDownstreamQueryResponse,
  mockPipelineStagesQueryResponse,
  mockStages,
  mockUpstreamDownstreamQueryResponse,
  mockUpstreamQueryResponse,
} from './mock_data';

jest.mock('~/alert');

Vue.use(VueApollo);

describe('Commit box pipeline mini graph', () => {
  let wrapper;

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findPipelineMiniGraph = () => wrapper.findComponent(PipelineMiniGraph);
  const findLegacyPipelineMiniGraph = () => wrapper.findComponent(LegacyPipelineMiniGraph);

  const downstreamHandler = jest.fn().mockResolvedValue(mockDownstreamQueryResponse);
  const failedHandler = jest.fn().mockRejectedValue(new Error('GraphQL error'));
  const stagesHandler = jest.fn().mockResolvedValue(mockPipelineStagesQueryResponse);
  const upstreamDownstreamHandler = jest
    .fn()
    .mockResolvedValue(mockUpstreamDownstreamQueryResponse);
  const upstreamHandler = jest.fn().mockResolvedValue(mockUpstreamQueryResponse);
  const advanceToNextFetch = () => {
    jest.advanceTimersByTime(COMMIT_BOX_POLL_INTERVAL);
  };

  const fullPath = 'gitlab-org/gitlab';
  const iid = '315';
  const createMockApolloProvider = (handler = downstreamHandler) => {
    const requestHandlers = [
      [getLinkedPipelinesQuery, handler],
      [getPipelineStagesQuery, stagesHandler],
    ];

    return createMockApollo(requestHandlers);
  };

  const createComponent = ({ handler, ciGraphqlPipelineMiniGraph = false } = {}) => {
    wrapper = extendedWrapper(
      shallowMount(CommitBoxPipelineMiniGraph, {
        propsData: {
          stages: mockStages,
        },
        provide: {
          fullPath,
          iid,
          dataMethod: 'graphql',
          graphqlResourceEtag: '/api/graphql:pipelines/id/320',
          glFeatures: {
            ciGraphqlPipelineMiniGraph,
          },
        },
        apolloProvider: createMockApolloProvider(handler),
      }),
    );
  };

  describe('loading state', () => {
    it('should display loading state when loading', () => {
      createComponent();

      expect(findLoadingIcon().exists()).toBe(true);
      expect(findLegacyPipelineMiniGraph().exists()).toBe(false);
    });
  });

  describe('loaded state', () => {
    beforeEach(async () => {
      await createComponent();
    });

    it('should not display loading state after the query is resolved', () => {
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findLegacyPipelineMiniGraph().exists()).toBe(true);
    });

    it('should display the pipeline mini graph', () => {
      expect(findLegacyPipelineMiniGraph().exists()).toBe(true);
    });
  });

  describe('load upstream/downstream', () => {
    const samplePipeline = {
      __typename: expect.any(String),
      id: expect.any(String),
      path: expect.any(String),
      project: expect.any(Object),
      detailedStatus: expect.any(Object),
    };

    it('formatted stages should be passed to the pipeline mini graph', async () => {
      const stage = mockStages[0];
      const expectedStages = [
        {
          name: stage.name,
          status: {
            __typename: 'DetailedStatus',
            id: stage.status.id,
            icon: stage.status.icon,
            group: stage.status.group,
          },
          dropdown_path: stage.dropdown_path,
          title: stage.title,
        },
      ];

      createComponent();

      await waitForPromises();

      expect(findLegacyPipelineMiniGraph().props('stages')).toEqual(expectedStages);
    });

    it('should render a downstream pipeline only', async () => {
      createComponent(downstreamHandler);

      await waitForPromises();

      const downstreamPipelines = findLegacyPipelineMiniGraph().props('downstreamPipelines');
      const upstreamPipeline = findLegacyPipelineMiniGraph().props('upstreamPipeline');

      expect(downstreamPipelines).toEqual(expect.any(Array));
      expect(upstreamPipeline).toEqual(null);
    });

    it('should render the latest downstream pipeline only', async () => {
      createComponent(downstreamHandler);

      await waitForPromises();

      const downstreamPipelines = findLegacyPipelineMiniGraph().props('downstreamPipelines');

      expect(downstreamPipelines).toHaveLength(1);
    });

    it('should pass the pipeline path prop for the counter badge', async () => {
      createComponent({ handler: downstreamHandler });

      await waitForPromises();

      const expectedPath = mockDownstreamQueryResponse.data.project.pipeline.path;
      const pipelinePath = findLegacyPipelineMiniGraph().props('pipelinePath');

      expect(pipelinePath).toBe(expectedPath);
    });

    it('should render an upstream pipeline only', async () => {
      createComponent({ handler: upstreamHandler });

      await waitForPromises();

      const downstreamPipelines = findLegacyPipelineMiniGraph().props('downstreamPipelines');
      const upstreamPipeline = findLegacyPipelineMiniGraph().props('upstreamPipeline');

      expect(upstreamPipeline).toEqual(samplePipeline);
      expect(downstreamPipelines).toHaveLength(0);
    });

    it('should render downstream and upstream pipelines', async () => {
      createComponent({ handler: upstreamDownstreamHandler });

      await waitForPromises();

      const downstreamPipelines = findLegacyPipelineMiniGraph().props('downstreamPipelines');
      const upstreamPipeline = findLegacyPipelineMiniGraph().props('upstreamPipeline');

      expect(upstreamPipeline).toEqual(samplePipeline);
      expect(downstreamPipelines).toEqual(
        expect.arrayContaining([
          {
            ...samplePipeline,
            sourceJob: expect.any(Object),
          },
        ]),
      );
    });
  });

  describe('error state', () => {
    it('createAlert should show if there is an error fetching the data', async () => {
      createComponent({ handler: failedHandler });

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'There was a problem fetching linked pipelines.',
      });
    });
  });

  describe('polling', () => {
    it('polling interval is set for linked pipelines', () => {
      createComponent();

      const expectedInterval = wrapper.vm.$apollo.queries.pipeline.options.pollInterval;

      expect(expectedInterval).toBe(COMMIT_BOX_POLL_INTERVAL);
    });

    it('polling interval is set for pipeline stages', () => {
      createComponent();

      const expectedInterval = wrapper.vm.$apollo.queries.pipelineStages.options.pollInterval;

      expect(expectedInterval).toBe(COMMIT_BOX_POLL_INTERVAL);
    });

    it('polls for stages and linked pipelines', async () => {
      createComponent();

      await waitForPromises();

      expect(stagesHandler).toHaveBeenCalledTimes(1);
      expect(downstreamHandler).toHaveBeenCalledTimes(1);

      advanceToNextFetch();
      await waitForPromises();

      expect(stagesHandler).toHaveBeenCalledTimes(2);
      expect(downstreamHandler).toHaveBeenCalledTimes(2);

      advanceToNextFetch();
      await waitForPromises();

      expect(stagesHandler).toHaveBeenCalledTimes(3);
      expect(downstreamHandler).toHaveBeenCalledTimes(3);
    });

    it('toggles query polling with visibility check', async () => {
      jest.spyOn(sharedGraphQlUtils, 'toggleQueryPollingByVisibility');

      createComponent();

      await waitForPromises();

      expect(sharedGraphQlUtils.toggleQueryPollingByVisibility).toHaveBeenCalledWith(
        wrapper.vm.$apollo.queries.pipelineStages,
      );
      expect(sharedGraphQlUtils.toggleQueryPollingByVisibility).toHaveBeenCalledWith(
        wrapper.vm.$apollo.queries.pipeline,
      );
    });
  });

  describe('feature flag behavior', () => {
    it.each`
      state    | showLegacyPipelineMiniGraph | showPipelineMiniGraph
      ${true}  | ${false}                    | ${true}
      ${false} | ${true}                     | ${false}
    `(
      'renders the correct component when the feature flag is set to $state',
      async ({ state, showLegacyPipelineMiniGraph, showPipelineMiniGraph }) => {
        createComponent({ ciGraphqlPipelineMiniGraph: state });

        await waitForPromises();

        expect(findLegacyPipelineMiniGraph().exists()).toBe(showLegacyPipelineMiniGraph);
        expect(findPipelineMiniGraph().exists()).toBe(showPipelineMiniGraph);
      },
    );

    it('skips queries when the feature flag is enabled', async () => {
      createComponent({ ciGraphqlPipelineMiniGraph: true });

      await waitForPromises();

      expect(stagesHandler).not.toHaveBeenCalled();
      expect(downstreamHandler).not.toHaveBeenCalled();
    });
  });
});
