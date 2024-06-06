import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlLoadingIcon } from '@gitlab/ui';

import { createAlert } from '~/alert';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';

import getPipelineMiniGraphQuery from '~/ci/pipeline_mini_graph/graphql/queries/get_pipeline_mini_graph.query.graphql';
import PipelineMiniGraph from '~/ci/pipeline_mini_graph/pipeline_mini_graph.vue';
import * as sharedGraphQlUtils from '~/graphql_shared/utils';

import { pipelineMiniGraphFetchError, mockPipelineMiniGraphQueryResponse } from './mock_data';

Vue.use(VueApollo);
jest.mock('~/alert');

describe('PipelineMiniGraph', () => {
  let wrapper;
  let pipelineMiniGraphResponse;

  const fullPath = 'gitlab-org/gitlab';
  const iid = '315';
  const pipelineEtag = '/api/graphql:pipelines/id/315';

  const createComponent = ({ pipelineMiniGraphHandler = pipelineMiniGraphResponse } = {}) => {
    const handlers = [[getPipelineMiniGraphQuery, pipelineMiniGraphHandler]];
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

  const findPipelineMiniGraph = () => wrapper.findComponent('[data-testid="pipeline-mini-graph"]');
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  beforeEach(() => {
    pipelineMiniGraphResponse = jest.fn().mockResolvedValue(mockPipelineMiniGraphQueryResponse);
  });

  describe('when initial query is loading', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows a loading icon and no mini graph', () => {
      expect(findLoadingIcon().exists()).toBe(true);
      expect(findPipelineMiniGraph().exists()).toBe(false);
    });
  });

  describe('when query has loaded', () => {
    it('does not show a loading icon', async () => {
      await createComponent();

      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('renders the Pipeline Mini Graph', async () => {
      await createComponent();

      expect(findPipelineMiniGraph().exists()).toBe(true);
    });

    it('fires the query', async () => {
      await createComponent();

      expect(pipelineMiniGraphResponse).toHaveBeenCalledWith({ iid, fullPath });
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
