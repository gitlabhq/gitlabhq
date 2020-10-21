import { shallowMount } from '@vue/test-utils';
import DagGraph from '~/pipelines/components/dag/dag_graph.vue';
import { IS_HIGHLIGHTED, LINK_SELECTOR, NODE_SELECTOR } from '~/pipelines/components/dag/constants';
import { highlightIn, highlightOut } from '~/pipelines/components/dag/interactions';
import { createSankey } from '~/pipelines/components/dag/drawing_utils';
import { removeOrphanNodes } from '~/pipelines/components/parsing_utils';
import { parsedData } from './mock_data';

describe('The DAG graph', () => {
  let wrapper;

  const getGraph = () => wrapper.find('.dag-graph-container > svg');
  const getAllLinks = () => wrapper.findAll(`.${LINK_SELECTOR}`);
  const getAllNodes = () => wrapper.findAll(`.${NODE_SELECTOR}`);
  const getAllLabels = () => wrapper.findAll('foreignObject');

  const createComponent = (propsData = {}) => {
    if (wrapper?.destroy) {
      wrapper.destroy();
    }

    wrapper = shallowMount(DagGraph, {
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

  describe('interactions', () => {
    const strokeOpacity = opacity => `stroke-opacity: ${opacity};`;
    const baseOpacity = () => wrapper.vm.$options.viewOptions.baseOpacity;

    describe('links', () => {
      const liveLink = () => getAllLinks().at(4);
      const otherLink = () => getAllLinks().at(1);

      describe('on hover', () => {
        it('sets the link opacity to baseOpacity and background links to 0.2', () => {
          liveLink().trigger('mouseover');
          expect(liveLink().attributes('style')).toBe(strokeOpacity(highlightIn));
          expect(otherLink().attributes('style')).toBe(strokeOpacity(highlightOut));
        });

        it('reverts the styles on mouseout', () => {
          liveLink().trigger('mouseover');
          liveLink().trigger('mouseout');
          expect(liveLink().attributes('style')).toBe(strokeOpacity(baseOpacity()));
          expect(otherLink().attributes('style')).toBe(strokeOpacity(baseOpacity()));
        });
      });

      describe('on click', () => {
        describe('toggles link liveness', () => {
          it('turns link on', () => {
            liveLink().trigger('click');
            expect(liveLink().attributes('style')).toBe(strokeOpacity(highlightIn));
            expect(otherLink().attributes('style')).toBe(strokeOpacity(highlightOut));
          });

          it('turns link off on second click', () => {
            liveLink().trigger('click');
            liveLink().trigger('click');
            expect(liveLink().attributes('style')).toBe(strokeOpacity(baseOpacity()));
            expect(otherLink().attributes('style')).toBe(strokeOpacity(baseOpacity()));
          });
        });

        it('the link remains live even after mouseout', () => {
          liveLink().trigger('click');
          liveLink().trigger('mouseout');
          expect(liveLink().attributes('style')).toBe(strokeOpacity(highlightIn));
          expect(otherLink().attributes('style')).toBe(strokeOpacity(highlightOut));
        });

        it('preserves state when multiple links are toggled on and off', () => {
          const anotherLiveLink = () => getAllLinks().at(2);

          liveLink().trigger('click');
          anotherLiveLink().trigger('click');
          expect(liveLink().attributes('style')).toBe(strokeOpacity(highlightIn));
          expect(anotherLiveLink().attributes('style')).toBe(strokeOpacity(highlightIn));
          expect(otherLink().attributes('style')).toBe(strokeOpacity(highlightOut));

          anotherLiveLink().trigger('click');
          expect(liveLink().attributes('style')).toBe(strokeOpacity(highlightIn));
          expect(anotherLiveLink().attributes('style')).toBe(strokeOpacity(highlightOut));
          expect(otherLink().attributes('style')).toBe(strokeOpacity(highlightOut));

          liveLink().trigger('click');
          expect(liveLink().attributes('style')).toBe(strokeOpacity(baseOpacity()));
          expect(anotherLiveLink().attributes('style')).toBe(strokeOpacity(baseOpacity()));
          expect(otherLink().attributes('style')).toBe(strokeOpacity(baseOpacity()));
        });
      });
    });

    describe('nodes', () => {
      const liveNode = () => getAllNodes().at(10);
      const anotherLiveNode = () => getAllNodes().at(5);
      const nodesNotHighlighted = () => getAllNodes().filter(n => !n.classes(IS_HIGHLIGHTED));
      const linksNotHighlighted = () => getAllLinks().filter(n => !n.classes(IS_HIGHLIGHTED));
      const nodesHighlighted = () => getAllNodes().filter(n => n.classes(IS_HIGHLIGHTED));
      const linksHighlighted = () => getAllLinks().filter(n => n.classes(IS_HIGHLIGHTED));

      describe('on click', () => {
        it('highlights the clicked node and predecessors', () => {
          liveNode().trigger('click');

          expect(nodesNotHighlighted().length < getAllNodes().length).toBe(true);
          expect(linksNotHighlighted().length < getAllLinks().length).toBe(true);

          linksHighlighted().wrappers.forEach(link => {
            expect(link.attributes('style')).toBe(strokeOpacity(highlightIn));
          });

          nodesHighlighted().wrappers.forEach(node => {
            expect(node.attributes('stroke')).not.toBe('#f2f2f2');
          });

          linksNotHighlighted().wrappers.forEach(link => {
            expect(link.attributes('style')).toBe(strokeOpacity(highlightOut));
          });

          nodesNotHighlighted().wrappers.forEach(node => {
            expect(node.attributes('stroke')).toBe('#f2f2f2');
          });
        });

        it('toggles path off on second click', () => {
          liveNode().trigger('click');
          liveNode().trigger('click');

          expect(nodesNotHighlighted().length).toBe(getAllNodes().length);
          expect(linksNotHighlighted().length).toBe(getAllLinks().length);
        });

        it('preserves state when multiple nodes are toggled on and off', () => {
          anotherLiveNode().trigger('click');
          liveNode().trigger('click');
          anotherLiveNode().trigger('click');
          expect(nodesNotHighlighted().length < getAllNodes().length).toBe(true);
          expect(linksNotHighlighted().length < getAllLinks().length).toBe(true);
        });
      });
    });
  });
});
