import { createSankey } from '~/pipelines/components/dag/drawing_utils';
import {
  createNodeDict,
  makeLinksFromNodes,
  filterByAncestors,
  generateColumnsFromLayersListBare,
  listByLayers,
  parseData,
  removeOrphanNodes,
  getMaxNodes,
} from '~/pipelines/components/parsing_utils';

import { mockParsedGraphQLNodes, missingJob } from './components/dag/mock_data';
import { generateResponse, mockPipelineResponse } from './graph/mock_data';

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

    it('does not generate a link for non-existing jobs', () => {
      const sources = unfilteredLinks.map(({ source }) => source);

      expect(sources.includes(missingJob)).toBe(false);
    });
  });

  describe('filterByAncestors', () => {
    const allLinks = [
      { source: 'job1', target: 'job4' },
      { source: 'job1', target: 'job2' },
      { source: 'job2', target: 'job4' },
    ];

    const dedupedLinks = [
      { source: 'job1', target: 'job2' },
      { source: 'job2', target: 'job4' },
    ];

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
      expect(parsed.nodes).toHaveLength(mockParsedGraphQLNodes.length);
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

  describe('generateColumnsFromLayersList', () => {
    const pipeline = generateResponse(mockPipelineResponse, 'root/fungi-xoxo');
    const layers = listByLayers(pipeline);
    const columns = generateColumnsFromLayersListBare(pipeline, layers);

    it('returns stage-like objects with default name, id, and status', () => {
      columns.forEach((col, idx) => {
        expect(col).toMatchObject({
          name: '',
          status: { action: null },
          id: `layer-${idx}`,
        });
      });
    });

    it('creates groups that match the list created in listByLayers', () => {
      columns.forEach((col, idx) => {
        const groupNames = col.groups.map(({ name }) => name);
        expect(groupNames).toEqual(layers[idx]);
      });
    });

    it('looks up the correct group object', () => {
      columns.forEach((col) => {
        col.groups.forEach((group) => {
          const groupStage = pipeline.stages.find((el) => el.name === group.stageName);
          const groupObject = groupStage.groups.find((el) => el.name === group.name);
          expect(group).toBe(groupObject);
        });
      });
    });

    /*
      Just as a fallback in case multiple functions change, so tests pass
      but the implementation moves away from case.
    */
    it('matches the snapshot', () => {
      expect(columns).toMatchSnapshot();
    });
  });
});
