import { mount, shallowMount } from '@vue/test-utils';
import PipelineGraph from '~/pipelines/components/graph/graph_component.vue';
import StageColumnComponent from '~/pipelines/components/graph/stage_column_component.vue';
import LinkedPipelinesColumn from '~/pipelines/components/graph/linked_pipelines_column.vue';
import LinksLayer from '~/pipelines/components/graph_shared/links_layer.vue';
import { GRAPHQL } from '~/pipelines/components/graph/constants';
import {
  generateResponse,
  mockPipelineResponse,
  pipelineWithUpstreamDownstream,
} from './mock_data';

describe('graph component', () => {
  let wrapper;

  const findLinkedColumns = () => wrapper.findAll(LinkedPipelinesColumn);
  const findLinksLayer = () => wrapper.find(LinksLayer);
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
      stubs: {
        'links-inner': true,
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

    it('renders the links layer', () => {
      expect(findLinksLayer().exists()).toBe(true);
    });

    describe('when column requests a refresh', () => {
      beforeEach(() => {
        findStageColumns().at(0).vm.$emit('refreshPipelineGraph');
      });

      it('refreshPipelineGraph is emitted', () => {
        expect(wrapper.emitted().refreshPipelineGraph).toHaveLength(1);
      });
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
