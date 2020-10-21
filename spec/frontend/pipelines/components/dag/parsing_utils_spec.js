import {
  createNodeDict,
  makeLinksFromNodes,
  filterByAncestors,
  parseData,
  removeOrphanNodes,
  getMaxNodes,
} from '~/pipelines/components/parsing_utils';

import { createSankey } from '~/pipelines/components/dag/drawing_utils';
import { mockParsedGraphQLNodes } from './mock_data';

describe('DAG visualization parsing utilities', () => {
  const nodeDict = createNodeDict(mockParsedGraphQLNodes);
  const unfilteredLinks = makeLinksFromNodes(mockParsedGraphQLNodes, nodeDict);
  const parsed = parseData(mockParsedGraphQLNodes);

  describe('makeLinksFromNodes', () => {
    it('returns the expected link structure', () => {
      expect(unfilteredLinks[0]).toHaveProperty('source', 'build_a');
      expect(unfilteredLinks[0]).toHaveProperty('target', 'test_a');
      expect(unfilteredLinks[0]).toHaveProperty('value', 10);
    });
  });

  describe('filterByAncestors', () => {
    const allLinks = [
      { source: 'job1', target: 'job4' },
      { source: 'job1', target: 'job2' },
      { source: 'job2', target: 'job4' },
    ];

    const dedupedLinks = [{ source: 'job1', target: 'job2' }, { source: 'job2', target: 'job4' }];

    const nodeLookup = {
      job1: {
        name: 'job1',
      },
      job2: {
        name: 'job2',
        needs: ['job1'],
      },
      job4: {
        name: 'job4',
        needs: ['job1', 'job2'],
        category: 'build',
      },
    };

    it('dedupes links', () => {
      expect(filterByAncestors(allLinks, nodeLookup)).toMatchObject(dedupedLinks);
    });
  });

  describe('parseData parent function', () => {
    it('returns an object containing a list of nodes and links', () => {
      // an array of nodes exist and the values are defined
      expect(parsed).toHaveProperty('nodes');
      expect(Array.isArray(parsed.nodes)).toBe(true);
      expect(parsed.nodes.filter(Boolean)).not.toHaveLength(0);

      // an array of links exist and the values are defined
      expect(parsed).toHaveProperty('links');
      expect(Array.isArray(parsed.links)).toBe(true);
      expect(parsed.links.filter(Boolean)).not.toHaveLength(0);
    });
  });

  describe('removeOrphanNodes', () => {
    it('removes sankey nodes that have no needs and are not needed', () => {
      const layoutSettings = {
        width: 200,
        height: 200,
        nodeWidth: 10,
        nodePadding: 20,
        paddingForLabels: 100,
      };

      const sankeyLayout = createSankey(layoutSettings)(parsed);
      const cleanedNodes = removeOrphanNodes(sankeyLayout.nodes);
      /*
        These lengths are determined by the mock data.
        If the data changes, the numbers may also change.
      */
      expect(parsed.nodes).toHaveLength(21);
      expect(cleanedNodes).toHaveLength(12);
    });
  });

  describe('getMaxNodes', () => {
    it('returns the number of nodes in the most populous generation', () => {
      const layerNodes = [
        { layer: 0 },
        { layer: 0 },
        { layer: 1 },
        { layer: 1 },
        { layer: 0 },
        { layer: 3 },
        { layer: 2 },
        { layer: 4 },
        { layer: 1 },
        { layer: 3 },
        { layer: 4 },
      ];
      expect(getMaxNodes(layerNodes)).toBe(3);
    });
  });
});
