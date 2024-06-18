import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlLoadingIcon } from '@gitlab/ui';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createAlert } from '~/alert';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';

import getPipelineMiniGraphQuery from '~/ci/pipeline_mini_graph/graphql/queries/get_pipeline_mini_graph.query.graphql';
import PipelineMiniGraph from '~/ci/pipeline_mini_graph/pipeline_mini_graph.vue';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import DownstreamPipelines from '~/ci/pipeline_mini_graph/downstream_pipelines.vue';
import PipelineStages from '~/ci/pipeline_mini_graph/pipeline_stages.vue';
import * as sharedGraphQlUtils from '~/graphql_shared/utils';

import {
  pipelineMiniGraphFetchError,
  mockPipelineMiniGraphQueryResponse,
  mockPMGQueryNoUpstreamResponse,
  mockPMGQueryNoDownstreamResponse,
} from './mock_data';

Vue.use(VueApollo);
jest.mock('~/alert');

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

  beforeEach(() => {
    pipelineMiniGraphResponse = jest.fn();
    pipelineMiniGraphResponse.mockResolvedValue(mockPipelineMiniGraphQueryResponse);
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

    describe('stages', () => {
      it('renders stages', () => {
        expect(findStages().exists()).toBe(true);
      });

      it('sends the necessary props', () => {
        expect(findStages().props()).toMatchObject({
          isMergeTrain: expect.any(Boolean),
          stages: expect.any(Array),
        });
      });
    });

    describe('upstream', () => {
      it('renders upstream if available', () => {
        expect(findUpstream().exists()).toBe(true);
      });

      it('does not render upstream if not available', () => {
        pipelineMiniGraphResponse.mockResolvedValue(mockPMGQueryNoUpstreamResponse);
        expect(findUpstream().exists()).toBe(true);
      });
    });

    describe('downstream', () => {
      it('renders downstream if available', () => {
        expect(findDownstream().exists()).toBe(true);
      });

      it('sends the necessary props', () => {
        expect(findDownstream().props()).toMatchObject({
          pipelines: expect.any(Array),
          pipelinePath: expect.any(String),
        });
      });

      it('does not render downstream if not available', () => {
        pipelineMiniGraphResponse.mockResolvedValue(mockPMGQueryNoDownstreamResponse);
        expect(findUpstream().exists()).toBe(true);
      });
    });
  });

  describe('polling', () => {
    it('toggles query polling with visibility check', async () => {
      jest.spyOn(sharedGraphQlUtils, 'toggleQueryPollingByVisibility');

      createComponent();

      await waitForPromises();

      expect(sharedGraphQlUtils.toggleQueryPollingByVisibility).toHaveBeenCalledTimes(1);
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
});
