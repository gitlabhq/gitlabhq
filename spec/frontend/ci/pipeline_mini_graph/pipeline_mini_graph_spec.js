import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import Visibility from 'visibilityjs';
import { GlLoadingIcon } from '@gitlab/ui';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createAlert } from '~/alert';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';

import { PIPELINE_POLL_INTERVAL_DEFAULT } from '~/ci/constants';
import getPipelineMiniGraphQuery from '~/ci/pipeline_mini_graph/graphql/queries/get_pipeline_mini_graph.query.graphql';
import PipelineMiniGraph from '~/ci/pipeline_mini_graph/pipeline_mini_graph.vue';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import DownstreamPipelines from '~/ci/pipeline_mini_graph/downstream_pipelines.vue';
import PipelineStages from '~/ci/pipeline_mini_graph/pipeline_stages.vue';

import {
  pipelineMiniGraphFetchError,
  mockPipelineMiniGraphQueryResponse,
  mockPMGQueryNoUpstreamResponse,
  mockPMGQueryNoDownstreamResponse,
} from './mock_data';

Vue.use(VueApollo);
jest.mock('~/alert');
jest.mock('visibilityjs');

describe('PipelineMiniGraph', () => {
  let wrapper;
  let pipelineMiniGraphResponse;

  const defaultProps = {
    fullPath: 'gitlab-org/gitlab',
    iid: '315',
    pipelineEtag: '/api/graphql:pipelines/id/315',
  };

  const createComponent = async ({ pipelineMiniGraphHandler = pipelineMiniGraphResponse } = {}) => {
    const handlers = [[getPipelineMiniGraphQuery, pipelineMiniGraphHandler]];
    const mockApollo = createMockApollo(handlers);

    wrapper = shallowMountExtended(PipelineMiniGraph, {
      propsData: {
        ...defaultProps,
      },
      apolloProvider: mockApollo,
    });

    await waitForPromises();
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findPipelineMiniGraph = () => wrapper.findComponent('[data-testid="pipeline-mini-graph"]');
  const findUpstream = () => wrapper.findComponent(CiIcon);
  const findDownstream = () => wrapper.findComponent(DownstreamPipelines);
  const findStages = () => wrapper.findComponent(PipelineStages);

  const getPollInterval = () => wrapper.vm.$apollo.queries.pipeline.pollInterval;

  beforeEach(() => {
    pipelineMiniGraphResponse = jest.fn();
  });

  describe('when initial query is loading', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders a loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('does not render the mini graph', () => {
      expect(findPipelineMiniGraph().exists()).toBe(false);
    });
  });

  describe('when query has loaded', () => {
    beforeEach(async () => {
      pipelineMiniGraphResponse.mockResolvedValue(mockPipelineMiniGraphQueryResponse);
      await createComponent();
    });

    it('does not show a loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('renders the Pipeline Mini Graph', () => {
      expect(findPipelineMiniGraph().exists()).toBe(true);
    });

    it('fires the query', () => {
      const { iid, fullPath } = defaultProps;

      expect(pipelineMiniGraphResponse).toHaveBeenCalledWith({ iid, fullPath });
    });
  });

  describe('stages', () => {
    beforeEach(async () => {
      pipelineMiniGraphResponse.mockResolvedValue(mockPipelineMiniGraphQueryResponse);
      await createComponent();
    });

    it('renders stages', () => {
      expect(findStages().exists()).toBe(true);
    });

    it('sends the necessary props', () => {
      expect(findStages().props()).toMatchObject({
        isMergeTrain: expect.any(Boolean),
        stages: expect.any(Array),
      });
    });

    it('emits miniGraphStageClick', () => {
      findStages().vm.$emit('miniGraphStageClick');
      expect(wrapper.emitted('miniGraphStageClick')).toHaveLength(1);
    });
  });

  describe('upstream', () => {
    it('renders upstream if available', async () => {
      pipelineMiniGraphResponse.mockResolvedValue(mockPipelineMiniGraphQueryResponse);
      await createComponent();
      expect(findUpstream().exists()).toBe(true);
    });

    it('does not render upstream if not available', () => {
      pipelineMiniGraphResponse.mockResolvedValue(mockPMGQueryNoUpstreamResponse);
      createComponent();
      expect(findUpstream().exists()).toBe(false);
    });
  });

  describe('downstream', () => {
    it('renders downstream if available', async () => {
      pipelineMiniGraphResponse.mockResolvedValue(mockPipelineMiniGraphQueryResponse);
      await createComponent();
      expect(findDownstream().exists()).toBe(true);
    });

    it('sends the necessary props', async () => {
      pipelineMiniGraphResponse.mockResolvedValue(mockPipelineMiniGraphQueryResponse);
      await createComponent();
      expect(findDownstream().props()).toMatchObject({
        pipelines: expect.any(Array),
        pipelinePath: expect.any(String),
      });
    });

    it('keeps the latest downstream pipelines', async () => {
      pipelineMiniGraphResponse.mockResolvedValue(mockPipelineMiniGraphQueryResponse);
      await createComponent();
      expect(findDownstream().props('pipelines')).toHaveLength(2);
    });

    it('does not render downstream if not available', () => {
      pipelineMiniGraphResponse.mockResolvedValue(mockPMGQueryNoDownstreamResponse);
      createComponent();
      expect(findDownstream().exists()).toBe(false);
    });
  });

  describe('when the pipeline query is unsuccessful', () => {
    const failedHandler = jest.fn().mockRejectedValue(new Error('GraphQL error'));

    it('throws an error for the pipeline query', async () => {
      await createComponent({ pipelineMiniGraphHandler: failedHandler });

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({ message: pipelineMiniGraphFetchError });
    });
  });

  describe('polling', () => {
    beforeEach(async () => {
      Visibility.hidden.mockReturnValue(true);
      pipelineMiniGraphResponse.mockResolvedValue(mockPipelineMiniGraphQueryResponse);
      await createComponent();
    });

    it('increases the poll interval after each query call', () => {
      expect(pipelineMiniGraphResponse).toHaveBeenCalled();
      expect(getPollInterval()).toBeGreaterThan(PIPELINE_POLL_INTERVAL_DEFAULT);
    });

    it('handles visibility change for polling correctly', async () => {
      expect(getPollInterval()).toBeGreaterThan(PIPELINE_POLL_INTERVAL_DEFAULT);

      Visibility.hidden.mockReturnValue(false);
      wrapper.vm.handlePolling();
      await nextTick();

      expect(getPollInterval()).toBe(PIPELINE_POLL_INTERVAL_DEFAULT);
    });

    it('resets poll interval on job action executed', async () => {
      expect(getPollInterval()).toBeGreaterThan(PIPELINE_POLL_INTERVAL_DEFAULT);

      findStages().vm.$emit('jobActionExecuted');
      await nextTick();

      expect(getPollInterval()).toBe(PIPELINE_POLL_INTERVAL_DEFAULT);
    });
  });
});
