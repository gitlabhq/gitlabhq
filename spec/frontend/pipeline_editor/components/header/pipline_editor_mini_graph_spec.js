import { shallowMount } from '@vue/test-utils';
import PipelineEditorMiniGraph from '~/pipeline_editor/components/header/pipeline_editor_mini_graph.vue';
import PipelineMiniGraph from '~/pipelines/components/pipelines_list/pipeline_mini_graph.vue';
import { mockProjectPipeline } from '../../mock_data';

describe('Pipeline Status', () => {
  let wrapper;

  const createComponent = ({ hasStages = true } = {}) => {
    wrapper = shallowMount(PipelineEditorMiniGraph, {
      propsData: {
        pipeline: mockProjectPipeline({ hasStages }).pipeline,
      },
    });
  };

  const findPipelineMiniGraph = () => wrapper.findComponent(PipelineMiniGraph);

  afterEach(() => {
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
});
