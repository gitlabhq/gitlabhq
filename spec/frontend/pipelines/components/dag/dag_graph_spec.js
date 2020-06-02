import { mount } from '@vue/test-utils';
import DagGraph from '~/pipelines/components/dag/dag_graph.vue';
import { createSankey } from '~/pipelines/components/dag/drawing_utils';
import { removeOrphanNodes } from '~/pipelines/components/dag/parsing_utils';
import { parsedData } from './mock_data';

describe('The DAG graph', () => {
  let wrapper;

  const getGraph = () => wrapper.find('.dag-graph-container > svg');
  const getAllLinks = () => wrapper.findAll('.dag-link');
  const getAllNodes = () => wrapper.findAll('.dag-node');
  const getAllLabels = () => wrapper.findAll('foreignObject');

  const createComponent = (propsData = {}) => {
    if (wrapper?.destroy) {
      wrapper.destroy();
    }

    wrapper = mount(DagGraph, {
      attachToDocument: true,
      propsData,
      data() {
        return {
          color: () => {},
          width: 0,
          height: 0,
        };
      },
    });
  };

  beforeEach(() => {
    createComponent({ graphData: parsedData });
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('in the basic case', () => {
    beforeEach(() => {
      /*
        The graph uses random to offset links. To keep the snapshot consistent,
        we mock Math.random. Wheeeee!
      */
      const randomNumber = jest.spyOn(global.Math, 'random');
      randomNumber.mockImplementation(() => 0.2);
      createComponent({ graphData: parsedData });
    });

    it('renders the graph svg', () => {
      expect(getGraph().exists()).toBe(true);
      expect(getGraph().html()).toMatchSnapshot();
    });
  });

  describe('links', () => {
    it('renders the expected number of links', () => {
      expect(getAllLinks()).toHaveLength(parsedData.links.length);
    });

    it('renders the expected number of gradients', () => {
      expect(wrapper.findAll('linearGradient')).toHaveLength(parsedData.links.length);
    });

    it('renders the expected number of clip paths', () => {
      expect(wrapper.findAll('clipPath')).toHaveLength(parsedData.links.length);
    });
  });

  describe('nodes and labels', () => {
    const sankeyNodes = createSankey()(parsedData).nodes;
    const processedNodes = removeOrphanNodes(sankeyNodes);

    describe('nodes', () => {
      it('renders the expected number of nodes', () => {
        expect(getAllNodes()).toHaveLength(processedNodes.length);
      });
    });

    describe('labels', () => {
      it('renders the expected number of labels as foreignObjects', () => {
        expect(getAllLabels()).toHaveLength(processedNodes.length);
      });

      it('renders the title as text', () => {
        expect(
          getAllLabels()
            .at(0)
            .text(),
        ).toBe(parsedData.nodes[0].name);
      });
    });
  });
});
