import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import CommitBoxPipelineMiniGraph from '~/projects/commit_box/info/components/commit_box_pipeline_mini_graph.vue';
import PipelineMiniGraph from '~/pipelines/components/pipelines_list/pipeline_mini_graph.vue';
import getLinkedPipelinesQuery from '~/projects/commit_box/info/graphql/queries/get_linked_pipelines.query.graphql';
import getPipelineStagesQuery from '~/projects/commit_box/info/graphql/queries/get_pipeline_stages.query.graphql';
import { mockPipelineStagesQueryResponse, mockStages } from './mock_data';

jest.mock('~/flash');

Vue.use(VueApollo);

describe('Commit box pipeline mini graph', () => {
  let wrapper;

  const findPipelineMiniGraph = () => wrapper.findComponent(PipelineMiniGraph);

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

    it('should display the pipeline mini graph', () => {
      expect(findPipelineMiniGraph().exists()).toBe(true);
    });

    it('should not display linked pipelines', () => {
      const downstreamPipelines = findPipelineMiniGraph().props('downstreamPipelines');
      const upstreamPipeline = findPipelineMiniGraph().props('upstreamPipeline');

      expect(downstreamPipelines).toHaveLength(0);
      expect(upstreamPipeline).toEqual(undefined);
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
