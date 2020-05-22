import {
  createNodesStructure,
  makeLinksFromNodes,
  filterByAncestors,
  parseData,
  createSankey,
  removeOrphanNodes,
  getMaxNodes,
} from '~/pipelines/components/dag/utils';

import mockGraphData from './mock_data';

describe('DAG visualization parsing utilities', () => {
  const { nodes, nodeDict } = createNodesStructure(mockGraphData.stages);
  const unfilteredLinks = makeLinksFromNodes(nodes, nodeDict);
  const parsed = parseData(mockGraphData.stages);

  const layoutSettings = {
    width: 200,
    height: 200,
    nodeWidth: 10,
    nodePadding: 20,
    paddingForLabels: 100,
  };

  const sankeyLayout = createSankey(layoutSettings)(parsed);

  describe('createNodesStructure', () => {
    const parallelGroupName = 'jest';
    const parallelJobName = 'jest 1/2';
    const singleJobName = 'frontend fixtures';

    const { name, jobs, size } = mockGraphData.stages[0].groups[0];

    it('returns the expected node structure', () => {
      expect(nodes[0]).toHaveProperty('category', mockGraphData.stages[0].name);
      expect(nodes[0]).toHaveProperty('name', name);
      expect(nodes[0]).toHaveProperty('jobs', jobs);
      expect(nodes[0]).toHaveProperty('size', size);
    });

    it('adds needs to top level of nodeDict entries', () => {
      expect(nodeDict[parallelGroupName]).toHaveProperty('needs');
      expect(nodeDict[parallelJobName]).toHaveProperty('needs');
      expect(nodeDict[singleJobName]).toHaveProperty('needs');
    });

    it('makes entries in nodeDict for jobs and parallel jobs', () => {
      const nodeNames = Object.keys(nodeDict);

      expect(nodeNames.includes(parallelGroupName)).toBe(true);
      expect(nodeNames.includes(parallelJobName)).toBe(true);
      expect(nodeNames.includes(singleJobName)).toBe(true);
    });
  });

  describe('makeLinksFromNodes', () => {
    it('returns the expected link structure', () => {
      expect(unfilteredLinks[0]).toHaveProperty('source', 'frontend fixtures');
      expect(unfilteredLinks[0]).toHaveProperty('target', 'jest');
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

  describe('createSankey', () => {
    it('returns a nodes data structure with expected d3-added properties', () => {
      expect(sankeyLayout.nodes[0]).toHaveProperty('sourceLinks');
      expect(sankeyLayout.nodes[0]).toHaveProperty('targetLinks');
      expect(sankeyLayout.nodes[0]).toHaveProperty('depth');
      expect(sankeyLayout.nodes[0]).toHaveProperty('layer');
      expect(sankeyLayout.nodes[0]).toHaveProperty('x0');
      expect(sankeyLayout.nodes[0]).toHaveProperty('x1');
      expect(sankeyLayout.nodes[0]).toHaveProperty('y0');
      expect(sankeyLayout.nodes[0]).toHaveProperty('y1');
    });

    it('returns a links data structure with expected d3-added properties', () => {
      expect(sankeyLayout.links[0]).toHaveProperty('source');
      expect(sankeyLayout.links[0]).toHaveProperty('target');
      expect(sankeyLayout.links[0]).toHaveProperty('width');
      expect(sankeyLayout.links[0]).toHaveProperty('y0');
      expect(sankeyLayout.links[0]).toHaveProperty('y1');
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

  describe('removeOrphanNodes', () => {
    it('removes sankey nodes that have no needs and are not needed', () => {
      const cleanedNodes = removeOrphanNodes(sankeyLayout.nodes);
      expect(cleanedNodes).toHaveLength(sankeyLayout.nodes.length - 1);
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
