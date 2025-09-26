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
import {
  NEEDS_PROPERTY,
  PREVIOUS_STAGE_JOBS_UNION_NEEDS_PROPERTY,
} from '~/ci/pipeline_details/constants';

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
        [NEEDS_PROPERTY]: ['job1'],
      },
      job4: {
        name: 'job4',
        [NEEDS_PROPERTY]: ['job1', 'job2'],
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

  describe('listByLayers', () => {
    describe('data source separation for linksData vs pipelineLayers', () => {
      const mockPipelineData = {
        stages: [
          {
            groups: [
              {
                name: 'build_job',
                jobs: [
                  {
                    name: 'build_job',
                    [NEEDS_PROPERTY]: [],
                    [PREVIOUS_STAGE_JOBS_UNION_NEEDS_PROPERTY]: [],
                  },
                ],
              },
            ],
          },
          {
            groups: [
              {
                name: 'test_with_needs',
                jobs: [
                  {
                    name: 'test_with_needs',
                    [NEEDS_PROPERTY]: ['build_job'],
                    [PREVIOUS_STAGE_JOBS_UNION_NEEDS_PROPERTY]: ['build_job'],
                  },
                ],
              },
              {
                name: 'test_with_union_only',
                jobs: [
                  {
                    name: 'test_with_union_only',
                    [NEEDS_PROPERTY]: [],
                    [PREVIOUS_STAGE_JOBS_UNION_NEEDS_PROPERTY]: ['build_job'],
                  },
                ],
              },
            ],
          },
        ],
      };

      it('uses NEEDS_PROPERTY for linksData', () => {
        const result = listByLayers(mockPipelineData);

        const linkTargets = result.linksData.map((link) => link.target);
        expect(linkTargets).toContain('test_with_needs');
        expect(linkTargets).not.toContain('test_with_union_only');
      });

      it('uses PREVIOUS_STAGE_JOBS_UNION_NEEDS_PROPERTY for pipelineLayers grouping', () => {
        const result = listByLayers(mockPipelineData);

        expect(result.pipelineLayers).toHaveLength(2);
        expect(result.pipelineLayers[0]).toEqual(['build_job']);
        expect(result.pipelineLayers[1]).toEqual(
          expect.arrayContaining(['test_with_needs', 'test_with_union_only']),
        );
      });
    });

    describe('parseData', () => {
      describe('with different needsKey parameters', () => {
        const mockNodes = [
          {
            name: 'build_job',
            category: 'build',
            size: 1,
            jobs: [
              {
                name: 'build_job',
                [NEEDS_PROPERTY]: [],
                [PREVIOUS_STAGE_JOBS_UNION_NEEDS_PROPERTY]: [],
              },
            ],
          },
          {
            name: 'test_job',
            category: 'test',
            size: 1,
            jobs: [
              {
                name: 'test_job',
                [NEEDS_PROPERTY]: ['build_job'],
                [PREVIOUS_STAGE_JOBS_UNION_NEEDS_PROPERTY]: ['build_job'],
              },
            ],
          },
          {
            name: 'deploy_job',
            category: 'deploy',
            size: 1,
            jobs: [
              {
                name: 'deploy_job',
                [NEEDS_PROPERTY]: [],
                [PREVIOUS_STAGE_JOBS_UNION_NEEDS_PROPERTY]: ['test_job'],
              },
            ],
          },
        ];

        it('creates different links when using NEEDS_PROPERTY vs PREVIOUS_STAGE_JOBS_UNION_NEEDS_PROPERTY', () => {
          const needsResult = parseData(mockNodes, { needsKey: NEEDS_PROPERTY });
          const unionResult = parseData(mockNodes, {
            needsKey: PREVIOUS_STAGE_JOBS_UNION_NEEDS_PROPERTY,
          });

          expect(needsResult.links).toHaveLength(1);
          expect(needsResult.links[0]).toMatchObject({
            source: 'build_job',
            target: 'test_job',
          });

          expect(unionResult.links).toHaveLength(2);
          expect(unionResult.links[0]).toMatchObject({
            source: 'build_job',
            target: 'test_job',
          });
          expect(unionResult.links[1]).toMatchObject({
            source: 'test_job',
            target: 'deploy_job',
          });
        });

        it('uses NEEDS_PROPERTY by default', () => {
          const defaultResult = parseData(mockNodes);
          const explicitNeedsResult = parseData(mockNodes, { needsKey: NEEDS_PROPERTY });

          expect(defaultResult.links).toEqual(explicitNeedsResult.links);
        });

        it('handles jobs with only union dependencies when using PREVIOUS_STAGE_JOBS_UNION_NEEDS_PROPERTY', () => {
          const unionResult = parseData(mockNodes, {
            needsKey: PREVIOUS_STAGE_JOBS_UNION_NEEDS_PROPERTY,
          });

          const deployLinks = unionResult.links.filter((link) => link.target === 'deploy_job');
          expect(deployLinks).toHaveLength(1);
        });

        it('ignores union dependencies when using NEEDS_PROPERTY', () => {
          const needsResult = parseData(mockNodes, { needsKey: NEEDS_PROPERTY });

          const deployLinks = needsResult.links.filter((link) => link.target === 'deploy_job');
          expect(deployLinks).toHaveLength(0);
        });
      });

      describe('data transformation accuracy and edge cases', () => {
        it('handles empty nodes array', () => {
          const result = parseData([]);

          expect(result.nodes).toEqual([]);
          expect(result.links).toEqual([]);
        });

        it('handles nodes with missing dependency properties', () => {
          const nodesWithMissingProps = [
            {
              name: 'job_without_deps',
              category: 'test',
              size: 1,
              jobs: [{ name: 'job_without_deps' }],
            },
          ];

          const result = parseData(nodesWithMissingProps);

          expect(result.nodes).toHaveLength(1);
          expect(result.links).toHaveLength(0);
        });

        it('filters out links to non-existent jobs', () => {
          const nodesWithMissingDeps = [
            {
              name: 'job_with_missing_dep',
              category: 'test',
              size: 1,
              jobs: [
                {
                  name: 'job_with_missing_dep',
                  [NEEDS_PROPERTY]: ['non_existent_job', 'another_missing_job'],
                },
              ],
            },
          ];

          const result = parseData(nodesWithMissingDeps);

          expect(result.nodes).toHaveLength(1);
          expect(result.links).toHaveLength(0);
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
