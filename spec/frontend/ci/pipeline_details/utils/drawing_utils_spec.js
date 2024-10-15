import { createSankey } from '~/ci/pipeline_details/utils/drawing_utils';
import { parseData } from '~/ci/pipeline_details/utils/parsing_utils';
import { mockParsedGraphQLNodes } from './mock_data';

describe('DAG visualization drawing utilities', () => {
  const parsed = parseData(mockParsedGraphQLNodes);

  const layoutSettings = {
    width: 200,
    height: 200,
    nodeWidth: 10,
    nodePadding: 20,
    paddingForLabels: 100,
  };

  const sankeyLayout = createSankey(layoutSettings)(parsed);

  describe('createSankey', () => {
    it('returns a nodes data structure with expected d3-added properties', () => {
      const exampleNode = sankeyLayout.nodes[0];
      expect(exampleNode).toHaveProperty('sourceLinks');
      expect(exampleNode).toHaveProperty('targetLinks');
      expect(exampleNode).toHaveProperty('depth');
      expect(exampleNode).toHaveProperty('layer');
      expect(exampleNode).toHaveProperty('x0');
      expect(exampleNode).toHaveProperty('x1');
      expect(exampleNode).toHaveProperty('y0');
      expect(exampleNode).toHaveProperty('y1');
    });

    it('returns a links data structure with expected d3-added properties', () => {
      const exampleLink = sankeyLayout.links[0];
      expect(exampleLink).toHaveProperty('source');
      expect(exampleLink).toHaveProperty('target');
      expect(exampleLink).toHaveProperty('width');
      expect(exampleLink).toHaveProperty('y0');
      expect(exampleLink).toHaveProperty('y1');
    });

    describe('data structure integrity', () => {
      const newObject = { name: 'bad-actor' };

      beforeEach(() => {
        sankeyLayout.nodes.unshift(newObject);
      });

      it('sankey does not propagate changes back to the original', () => {
        expect(sankeyLayout.nodes[0]).toBe(newObject);
        expect(parsed.nodes[0]).not.toBe(newObject);
      });

      afterEach(() => {
        sankeyLayout.nodes.shift();
      });
    });
  });
});
