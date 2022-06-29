import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import CommitBoxPipelineMiniGraph from '~/projects/commit_box/info/components/commit_box_pipeline_mini_graph.vue';
import getLinkedPipelinesQuery from '~/projects/commit_box/info/graphql/queries/get_linked_pipelines.query.graphql';
import getPipelineStagesQuery from '~/projects/commit_box/info/graphql/queries/get_pipeline_stages.query.graphql';
import { mockPipelineStagesQueryResponse, mockStages } from './mock_data';

jest.mock('~/flash');

Vue.use(VueApollo);

describe('Commit box pipeline mini graph', () => {
  let wrapper;

  const findMiniGraph = () => wrapper.findByTestId('commit-box-mini-graph');
  const findUpstream = () => wrapper.findByTestId('commit-box-mini-graph-upstream');
  const findDownstream = () => wrapper.findByTestId('commit-box-mini-graph-downstream');

  const stagesHandler = jest.fn().mockResolvedValue(mockPipelineStagesQueryResponse);

  const createComponent = ({ props = {} } = {}) => {
    const handlers = [
      [getLinkedPipelinesQuery, {}],
      [getPipelineStagesQuery, stagesHandler],
    ];

    wrapper = extendedWrapper(
      shallowMount(CommitBoxPipelineMiniGraph, {
        propsData: {
          stages: mockStages,
          ...props,
        },
        apolloProvider: createMockApollo(handlers),
      }),
    );

    return waitForPromises();
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('linked pipelines', () => {
    beforeEach(async () => {
      await createComponent();
    });

    it('should display the mini pipeine graph', () => {
      expect(findMiniGraph().exists()).toBe(true);
    });

    it('should not display linked pipelines', () => {
      expect(findUpstream().exists()).toBe(false);
      expect(findDownstream().exists()).toBe(false);
    });
  });

  describe('when data is mismatched', () => {
    beforeEach(async () => {
      await createComponent({ props: { stages: [] } });
    });

    it('calls create flash with expected arguments', () => {
      expect(createFlash).toHaveBeenCalledWith({
        message: 'There was a problem handling the pipeline data.',
        captureError: true,
        error: new Error('Rest stages and graphQl stages must be the same length'),
      });
    });
  });
});
