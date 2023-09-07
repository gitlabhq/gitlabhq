import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlLoadingIcon } from '@gitlab/ui';

import { createAlert } from '~/alert';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';

import getLinkedPipelinesQuery from '~/ci/pipeline_details/graphql/queries/get_linked_pipelines.query.graphql';
import getPipelineStagesQuery from '~/ci/pipeline_mini_graph/graphql/queries/get_pipeline_stages.query.graphql';
import LegacyPipelineMiniGraph from '~/ci/pipeline_mini_graph/legacy_pipeline_mini_graph.vue';
import PipelineMiniGraph from '~/ci/pipeline_mini_graph/pipeline_mini_graph.vue';
import * as sharedGraphQlUtils from '~/graphql_shared/utils';

import {
  linkedPipelinesFetchError,
  stagesFetchError,
  mockPipelineStagesQueryResponse,
  mockUpstreamDownstreamQueryResponse,
} from './mock_data';

Vue.use(VueApollo);
jest.mock('~/alert');

describe('PipelineMiniGraph', () => {
  let wrapper;
  let linkedPipelinesResponse;
  let pipelineStagesResponse;

  const fullPath = 'gitlab-org/gitlab';
  const iid = '315';
  const pipelineEtag = '/api/graphql:pipelines/id/315';

  const createComponent = ({
    pipelineStagesHandler = pipelineStagesResponse,
    linkedPipelinesHandler = linkedPipelinesResponse,
  } = {}) => {
    const handlers = [
      [getLinkedPipelinesQuery, linkedPipelinesHandler],
      [getPipelineStagesQuery, pipelineStagesHandler],
    ];
    const mockApollo = createMockApollo(handlers);

    wrapper = shallowMountExtended(PipelineMiniGraph, {
      propsData: {
        fullPath,
        iid,
        pipelineEtag,
      },
      apolloProvider: mockApollo,
    });

    return waitForPromises();
  };

  const findLegacyPipelineMiniGraph = () => wrapper.findComponent(LegacyPipelineMiniGraph);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  beforeEach(() => {
    linkedPipelinesResponse = jest.fn().mockResolvedValue(mockUpstreamDownstreamQueryResponse);
    pipelineStagesResponse = jest.fn().mockResolvedValue(mockPipelineStagesQueryResponse);
  });

  describe('when initial queries are loading', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows a loading icon and no mini graph', () => {
      expect(findLoadingIcon().exists()).toBe(true);
      expect(findLegacyPipelineMiniGraph().exists()).toBe(false);
    });
  });

  describe('when queries have loaded', () => {
    it('does not show a loading icon', async () => {
      await createComponent();

      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('renders the Pipeline Mini Graph', async () => {
      await createComponent();

      expect(findLegacyPipelineMiniGraph().exists()).toBe(true);
    });

    it('fires the queries', async () => {
      await createComponent();

      expect(linkedPipelinesResponse).toHaveBeenCalledWith({ iid, fullPath });
      expect(pipelineStagesResponse).toHaveBeenCalledWith({ iid, fullPath });
    });
  });

  describe('polling', () => {
    it('toggles query polling with visibility check', async () => {
      jest.spyOn(sharedGraphQlUtils, 'toggleQueryPollingByVisibility');

      createComponent();

      await waitForPromises();

      expect(sharedGraphQlUtils.toggleQueryPollingByVisibility).toHaveBeenCalledTimes(2);
    });
  });

  describe('when pipeline queries are unsuccessful', () => {
    const failedHandler = jest.fn().mockRejectedValue(new Error('GraphQL error'));
    it.each`
      query                 | handlerName                 | errorMessage
      ${'pipeline stages'}  | ${'pipelineStagesHandler'}  | ${stagesFetchError}
      ${'linked pipelines'} | ${'linkedPipelinesHandler'} | ${linkedPipelinesFetchError}
    `('throws an error for the $query query', async ({ errorMessage, handlerName }) => {
      await createComponent({ [handlerName]: failedHandler });

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({ message: errorMessage });
    });
  });
});
