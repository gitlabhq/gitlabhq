import { shallowMount } from '@vue/test-utils';
import PipelineGraph from '~/pipelines/components/graph/graph_component.vue';
import StageColumnComponent from '~/pipelines/components/graph/stage_column_component.vue';
import LinkedPipelinesColumn from '~/pipelines/components/graph/linked_pipelines_column.vue';
import { unwrapPipelineData } from '~/pipelines/components/graph/utils';
import { mockPipelineResponse } from './mock_data';

describe('graph component', () => {
  let wrapper;

  const findLinkedColumns = () => wrapper.findAll(LinkedPipelinesColumn);
  const findStageColumns = () => wrapper.findAll(StageColumnComponent);

  const generateResponse = raw => unwrapPipelineData(raw.data.project.pipeline.id, raw.data);

  const defaultProps = {
    pipeline: generateResponse(mockPipelineResponse),
  };

  const createComponent = ({ mountFn = shallowMount, props = {} } = {}) => {
    wrapper = mountFn(PipelineGraph, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('with data', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the main columns in the graph', () => {
      expect(findStageColumns()).toHaveLength(defaultProps.pipeline.stages.length);
    });
  });

  describe('when linked pipelines are not present', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should not render a linked pipelines column', () => {
      expect(findLinkedColumns()).toHaveLength(0);
    });
  });
});
