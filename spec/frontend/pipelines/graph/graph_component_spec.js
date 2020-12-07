import { mount, shallowMount } from '@vue/test-utils';
import PipelineGraph from '~/pipelines/components/graph/graph_component.vue';
import StageColumnComponent from '~/pipelines/components/graph/stage_column_component.vue';
import LinkedPipelinesColumn from '~/pipelines/components/graph/linked_pipelines_column.vue';
import { GRAPHQL } from '~/pipelines/components/graph/constants';
import {
  generateResponse,
  mockPipelineResponse,
  pipelineWithUpstreamDownstream,
} from './mock_data';

describe('graph component', () => {
  let wrapper;

  const findLinkedColumns = () => wrapper.findAll(LinkedPipelinesColumn);
  const findStageColumns = () => wrapper.findAll(StageColumnComponent);

  const defaultProps = {
    pipeline: generateResponse(mockPipelineResponse, 'root/fungi-xoxo'),
  };

  const createComponent = ({ mountFn = shallowMount, props = {} } = {}) => {
    wrapper = mountFn(PipelineGraph, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        dataMethod: GRAPHQL,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('with data', () => {
    beforeEach(() => {
      createComponent({ mountFn: mount });
    });

    it('renders the main columns in the graph', () => {
      expect(findStageColumns()).toHaveLength(defaultProps.pipeline.stages.length);
    });
  });

  describe('when linked pipelines are not present', () => {
    beforeEach(() => {
      createComponent({ mountFn: mount });
    });

    it('should not render a linked pipelines column', () => {
      expect(findLinkedColumns()).toHaveLength(0);
    });
  });

  describe('when linked pipelines are present', () => {
    beforeEach(() => {
      createComponent({
        mountFn: mount,
        props: { pipeline: pipelineWithUpstreamDownstream(mockPipelineResponse) },
      });
    });

    it('should render linked pipelines columns', () => {
      expect(findLinkedColumns()).toHaveLength(2);
    });
  });
});
