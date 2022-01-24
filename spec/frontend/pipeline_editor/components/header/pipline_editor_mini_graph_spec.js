import { shallowMount, createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import PipelineEditorMiniGraph from '~/pipeline_editor/components/header/pipeline_editor_mini_graph.vue';
import PipelineMiniGraph from '~/pipelines/components/pipelines_list/pipeline_mini_graph.vue';
import getLinkedPipelinesQuery from '~/projects/commit_box/info/graphql/queries/get_linked_pipelines.query.graphql';
import { PIPELINE_FAILURE } from '~/pipeline_editor/constants';
import { mockLinkedPipelines, mockProjectFullPath, mockProjectPipeline } from '../../mock_data';

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('Pipeline Status', () => {
  let wrapper;
  let mockApollo;
  let mockLinkedPipelinesQuery;

  const createComponent = ({ hasStages = true, options } = {}) => {
    wrapper = shallowMount(PipelineEditorMiniGraph, {
      provide: {
        dataMethod: 'graphql',
        projectFullPath: mockProjectFullPath,
      },
      propsData: {
        pipeline: mockProjectPipeline({ hasStages }).pipeline,
      },
      ...options,
    });
  };

  const createComponentWithApollo = (hasStages = true) => {
    const handlers = [[getLinkedPipelinesQuery, mockLinkedPipelinesQuery]];
    mockApollo = createMockApollo(handlers);

    createComponent({
      hasStages,
      options: {
        localVue,
        apolloProvider: mockApollo,
      },
    });
  };

  const findPipelineMiniGraph = () => wrapper.findComponent(PipelineMiniGraph);

  beforeEach(() => {
    mockLinkedPipelinesQuery = jest.fn();
  });

  afterEach(() => {
    mockLinkedPipelinesQuery.mockReset();
    wrapper.destroy();
  });

  describe('when there are stages', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders pipeline mini graph', () => {
      expect(findPipelineMiniGraph().exists()).toBe(true);
    });
  });

  describe('when there are no stages', () => {
    beforeEach(() => {
      createComponent({ hasStages: false });
    });

    it('does not render pipeline mini graph', () => {
      expect(findPipelineMiniGraph().exists()).toBe(false);
    });
  });

  describe('when querying upstream and downstream pipelines', () => {
    describe('when query succeeds', () => {
      beforeEach(() => {
        mockLinkedPipelinesQuery.mockResolvedValue(mockLinkedPipelines());
        createComponentWithApollo();
      });

      it('should call the query with the correct variables', () => {
        expect(mockLinkedPipelinesQuery).toHaveBeenCalledTimes(1);
        expect(mockLinkedPipelinesQuery).toHaveBeenCalledWith({
          fullPath: mockProjectFullPath,
          iid: mockProjectPipeline().pipeline.iid,
        });
      });
    });

    describe('when query fails', () => {
      beforeEach(async () => {
        mockLinkedPipelinesQuery.mockRejectedValue(new Error());
        createComponentWithApollo();
        await waitForPromises();
      });

      it('should emit an error event when query fails', async () => {
        expect(wrapper.emitted('showError')).toHaveLength(2);
        expect(wrapper.emitted('showError')[0]).toEqual([
          {
            type: PIPELINE_FAILURE,
            reasons: [wrapper.vm.$options.i18n.linkedPipelinesFetchError],
          },
        ]);
      });
    });
  });
});
