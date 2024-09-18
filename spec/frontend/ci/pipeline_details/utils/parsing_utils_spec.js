import mockPipelineResponse from 'test_fixtures/pipelines/pipeline_details.json';
import {
  makeLinksFromNodes,
  filterByAncestors,
  generateColumnsFromLayersListBare,
  keepLatestDownstreamPipelines,
  listByLayers,
  parseData,
  getMaxNodes,
} from '~/ci/pipeline_details/utils/parsing_utils';
import { createNodeDict } from '~/ci/pipeline_details/utils';

import { mockDownstreamPipelinesRest } from '../../../vue_merge_request_widget/mock_data';
import { mockDownstreamPipelinesGraphql } from '../../../commit/mock_data';
import { generateResponse } from '../graph/mock_data';
import { mockParsedGraphQLNodes, missingJob } from './mock_data';

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
    const { pipelineLayers } = listByLayers(pipeline);
    const columns = generateColumnsFromLayersListBare(pipeline, pipelineLayers);

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
        expect(groupNames).toEqual(pipelineLayers[idx]);
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
  });
});

describe('linked pipeline utilities', () => {
  describe('keepLatestDownstreamPipelines', () => {
    it('filters data from GraphQL', () => {
      const downstream = mockDownstreamPipelinesGraphql().nodes;
      const latestDownstream = keepLatestDownstreamPipelines(downstream);

      expect(downstream).toHaveLength(3);
      expect(latestDownstream).toHaveLength(1);
    });

    it('filters data from REST', () => {
      const downstream = mockDownstreamPipelinesRest();
      const latestDownstream = keepLatestDownstreamPipelines(downstream);

      expect(downstream).toHaveLength(2);
      expect(latestDownstream).toHaveLength(1);
    });

    it('returns downstream pipelines if sourceJob.retried is null', () => {
      const downstream = mockDownstreamPipelinesGraphql({ includeSourceJobRetried: false }).nodes;
      const latestDownstream = keepLatestDownstreamPipelines(downstream);

      expect(latestDownstream).toHaveLength(downstream.length);
    });

    it('returns downstream pipelines if source_job.retried is null', () => {
      const downstream = mockDownstreamPipelinesRest({ includeSourceJobRetried: false });
      const latestDownstream = keepLatestDownstreamPipelines(downstream);

      expect(latestDownstream).toHaveLength(downstream.length);
    });
  });
});
