import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';

import getPipelineStageQuery from '~/ci/pipeline_mini_graph/graphql/queries/get_pipeline_stage.query.graphql';
import PipelineStage from '~/ci/pipeline_mini_graph/pipeline_stage.vue';

Vue.use(VueApollo);

describe('PipelineStage', () => {
  let wrapper;
  let pipelineStageResponse;

  const defaultProps = {
    pipelineEtag: '/etag',
    stageId: '1',
  };

  const createComponent = ({ pipelineStageHandler = pipelineStageResponse } = {}) => {
    const handlers = [[getPipelineStageQuery, pipelineStageHandler]];
    const mockApollo = createMockApollo(handlers);

    wrapper = shallowMountExtended(PipelineStage, {
      propsData: {
        ...defaultProps,
      },
      apolloProvider: mockApollo,
    });

    return waitForPromises();
  };

  const findPipelineStage = () => wrapper.findComponent(PipelineStage);

  describe('when mounted', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders job item', () => {
      expect(findPipelineStage().exists()).toBe(true);
    });
  });
});
