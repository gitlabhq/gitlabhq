import {
  unwrapGroups,
  unwrapNodesWithName,
  unwrapJobWithNeeds,
  unwrapStagesWithNeedsAndLookup,
  unwrapStagesFromMutation,
} from '~/ci/pipeline_details/utils/unwrapping_utils';
import {
  NEEDS_PROPERTY,
  ALL_JOBS_FROM_PREVIOUS_STAGE_PROPERTY,
} from '~/ci/pipeline_details/constants';

const groupsArray = [
  {
    name: 'build_a',
    size: 1,
    status: {
      label: 'passed',
      group: 'success',
      icon: 'status_success',
    },
  },
  {
    name: 'bob_the_build',
    size: 1,
    status: {
      label: 'passed',
      group: 'success',
      icon: 'status_success',
    },
  },
];

const basicStageInfo = {
  name: 'center_stage',
  status: {
    action: null,
  },
};

const stagesAndGroups = [
  {
    ...basicStageInfo,
    groups: {
      nodes: groupsArray,
    },
  },
];

const needArray = [
  {
    name: 'build_b',
  },
];

const elephantArray = [
  {
    name: 'build_b',
    elephant: 'gray',
  },
];

const baseJobs = {
  name: 'test_d',
  status: {
    icon: 'status_success',
    tooltip: null,
    hasDetails: true,
    detailsPath: '/root/abcd-dag/-/pipelines/162',
    group: 'success',
    action: null,
  },
};

const jobArrayWithNeeds = [
  {
    ...baseJobs,
    [NEEDS_PROPERTY]: {
      nodes: needArray,
    },
  },
];

const jobArrayWithElephant = [
  {
    ...baseJobs,
    [NEEDS_PROPERTY]: {
      nodes: elephantArray,
    },
  },
];

describe('Shared pipeline unwrapping utils', () => {
  describe('unwrapGroups', () => {
    it('takes stages without nodes and returns the unwrapped groups', () => {
      expect(unwrapGroups(stagesAndGroups)[0].node.groups).toEqual(groupsArray);
    });

    it('keeps other stage properties intact', () => {
      expect(unwrapGroups(stagesAndGroups)[0].node).toMatchObject(basicStageInfo);
    });
  });

  describe('unwrapNodesWithName', () => {
    it('works with no field argument', () => {
      expect(unwrapNodesWithName(jobArrayWithNeeds, 'needs')[0][NEEDS_PROPERTY]).toEqual([
        needArray[0].name,
      ]);
    });

    it('works with custom field argument', () => {
      expect(
        unwrapNodesWithName(jobArrayWithElephant, 'needs', 'elephant')[0][NEEDS_PROPERTY],
      ).toEqual([elephantArray[0].elephant]);
    });

    it('works with .nodes format (query response)', () => {
      const jobsWithNodesFormat = [
        {
          ...baseJobs,
          [NEEDS_PROPERTY]: {
            nodes: [{ name: 'build_a' }, { name: 'build_b' }],
          },
        },
      ];

      const result = unwrapNodesWithName(jobsWithNodesFormat, NEEDS_PROPERTY);

      expect(result[0][NEEDS_PROPERTY]).toEqual(['build_a', 'build_b']);
    });

    it('works with direct array format (mutation response)', () => {
      const jobsWithDirectArrayFormat = [
        {
          ...baseJobs,
          [NEEDS_PROPERTY]: [{ name: 'build_a' }, { name: 'build_b' }],
        },
      ];

      const result = unwrapNodesWithName(jobsWithDirectArrayFormat, NEEDS_PROPERTY);

      expect(result[0][NEEDS_PROPERTY]).toEqual(['build_a', 'build_b']);
    });
  });

  describe('unwrapJobWithNeeds', () => {
    describe('ALL_JOBS_FROM_PREVIOUS_STAGE_PROPERTY addition', () => {
      it('creates union of previous stage jobs and explicit needs', () => {
        const previousStageJobs = ['prev_job_1', 'prev_job_2'];
        const jobArray = [
          {
            name: 'job_a',
            [NEEDS_PROPERTY]: { nodes: [{ name: 'dep_b' }] },
          },
        ];

        const result = unwrapJobWithNeeds(jobArray, previousStageJobs);

        expect(result).toEqual([
          {
            name: 'job_a',
            [NEEDS_PROPERTY]: ['dep_b'],
            [ALL_JOBS_FROM_PREVIOUS_STAGE_PROPERTY]: ['prev_job_1', 'prev_job_2', 'dep_b'],
          },
        ]);
      });

      it('uses previous stage jobs when job has no explicit needs', () => {
        const previousStageJobs = ['prev_job_1', 'prev_job_2'];
        const jobArray = [
          {
            name: 'job_b',
            [NEEDS_PROPERTY]: { nodes: [] },
          },
        ];

        const result = unwrapJobWithNeeds(jobArray, previousStageJobs);

        expect(result).toEqual([
          {
            name: 'job_b',
            [NEEDS_PROPERTY]: [],
            [ALL_JOBS_FROM_PREVIOUS_STAGE_PROPERTY]: ['prev_job_1', 'prev_job_2'],
          },
        ]);
      });

      it('uses empty array when no previous stage jobs and no explicit needs', () => {
        const jobArray = [
          {
            name: 'job_c',
            [NEEDS_PROPERTY]: { nodes: [] },
          },
        ];

        const result = unwrapJobWithNeeds(jobArray);

        expect(result).toEqual([
          {
            name: 'job_c',
            [NEEDS_PROPERTY]: [],
            [ALL_JOBS_FROM_PREVIOUS_STAGE_PROPERTY]: [],
          },
        ]);
      });

      it('deduplicates union when explicit needs overlap with previous stage jobs', () => {
        const previousStageJobs = ['build_a', 'build_b'];
        const jobArray = [
          {
            name: 'test_job',
            [NEEDS_PROPERTY]: { nodes: [{ name: 'build_a' }, { name: 'build_c' }] },
          },
        ];

        const result = unwrapJobWithNeeds(jobArray, previousStageJobs);

        expect(result).toEqual([
          {
            name: 'test_job',
            [NEEDS_PROPERTY]: ['build_a', 'build_c'],
            [ALL_JOBS_FROM_PREVIOUS_STAGE_PROPERTY]: ['build_a', 'build_b', 'build_c'],
          },
        ]);
      });
    });

    describe('data integrity through unwrapping process', () => {
      it('preserves original job properties', () => {
        const originalJob = {
          name: 'complex_job',
          id: '123',
          status: { icon: 'status_success', label: 'passed' },
          kind: 'BUILD',
          customProperty: 'should_be_preserved',
          [NEEDS_PROPERTY]: { nodes: [{ name: 'explicit_dep' }] },
        };

        const result = unwrapJobWithNeeds([originalJob]);

        expect(result[0].name).toBe('complex_job');
        expect(result[0].id).toBe('123');
        expect(result[0].status).toEqual({ icon: 'status_success', label: 'passed' });
        expect(result[0].kind).toBe('BUILD');
        expect(result[0].customProperty).toBe('should_be_preserved');
      });

      it('maintains job order', () => {
        const jobArray = [
          {
            name: 'first_job',
            [NEEDS_PROPERTY]: { nodes: [] },
          },
          {
            name: 'second_job',
            [NEEDS_PROPERTY]: { nodes: [] },
          },
          {
            name: 'third_job',
            [NEEDS_PROPERTY]: { nodes: [] },
          },
        ];

        const result = unwrapJobWithNeeds(jobArray);

        expect(result).toHaveLength(3);
        expect(result[0].name).toBe('first_job');
        expect(result[1].name).toBe('second_job');
        expect(result[2].name).toBe('third_job');
      });
    });
  });

  describe('unwrapStagesWithNeedsAndLookup', () => {
    it('correctly extracts all job names from previous stage across multiple groups', () => {
      const queryStages = [
        {
          name: 'build',
          groups: {
            nodes: [
              {
                name: 'build_group_1',
                jobs: {
                  nodes: [
                    { name: 'build_a', [NEEDS_PROPERTY]: { nodes: [] } },
                    { name: 'build_b', [NEEDS_PROPERTY]: { nodes: [] } },
                  ],
                },
              },
              {
                name: 'build_group_2',
                jobs: {
                  nodes: [
                    { name: 'build_c', [NEEDS_PROPERTY]: { nodes: [] } },
                    { name: 'build_d', [NEEDS_PROPERTY]: { nodes: [] } },
                  ],
                },
              },
            ],
          },
        },
        {
          name: 'test',
          groups: {
            nodes: [
              {
                name: 'test_group',
                jobs: {
                  nodes: [
                    {
                      name: 'test_job',
                      [NEEDS_PROPERTY]: { nodes: [] },
                    },
                  ],
                },
              },
            ],
          },
        },
      ];

      const { stages } = unwrapStagesWithNeedsAndLookup(queryStages);

      expect(stages).toMatchObject([
        {
          groups: [
            {
              jobs: [
                { [ALL_JOBS_FROM_PREVIOUS_STAGE_PROPERTY]: [] },
                { [ALL_JOBS_FROM_PREVIOUS_STAGE_PROPERTY]: [] },
              ],
            },
            {
              jobs: [
                { [ALL_JOBS_FROM_PREVIOUS_STAGE_PROPERTY]: [] },
                { [ALL_JOBS_FROM_PREVIOUS_STAGE_PROPERTY]: [] },
              ],
            },
          ],
        },
        {
          groups: [
            {
              jobs: [
                {
                  [ALL_JOBS_FROM_PREVIOUS_STAGE_PROPERTY]: [
                    'build_a',
                    'build_b',
                    'build_c',
                    'build_d',
                  ],
                },
              ],
            },
          ],
        },
      ]);
    });

    it('creates union of previous stage jobs and explicit needs with deduplication', () => {
      const queryStages = [
        {
          name: 'build',
          groups: {
            nodes: [
              {
                name: 'build_a',
                jobs: {
                  nodes: [{ name: 'build_a', [NEEDS_PROPERTY]: { nodes: [] } }],
                },
              },
              {
                name: 'build_b',
                jobs: {
                  nodes: [{ name: 'build_b', [NEEDS_PROPERTY]: { nodes: [] } }],
                },
              },
            ],
          },
        },
        {
          name: 'test',
          groups: {
            nodes: [
              {
                name: 'test_group',
                jobs: {
                  nodes: [
                    {
                      name: 'test_job',
                      [NEEDS_PROPERTY]: { nodes: [{ name: 'build_a' }] }, // Explicit needs
                    },
                  ],
                },
              },
            ],
          },
        },
      ];

      const { stages } = unwrapStagesWithNeedsAndLookup(queryStages);

      expect(stages[1].groups[0].jobs[0][NEEDS_PROPERTY]).toEqual(['build_a']);
      expect(stages[1].groups[0].jobs[0][ALL_JOBS_FROM_PREVIOUS_STAGE_PROPERTY]).toEqual([
        'build_a',
        'build_b',
      ]);

      expect(stages).toMatchObject([
        {
          groups: [
            {
              name: 'build_a',
              jobs: [{ [ALL_JOBS_FROM_PREVIOUS_STAGE_PROPERTY]: [], [NEEDS_PROPERTY]: [] }],
            },
            {
              name: 'build_b',
              jobs: [{ [ALL_JOBS_FROM_PREVIOUS_STAGE_PROPERTY]: [], [NEEDS_PROPERTY]: [] }],
            },
          ],
        },
        {
          groups: [
            {
              jobs: [
                {
                  [NEEDS_PROPERTY]: ['build_a'],
                  [ALL_JOBS_FROM_PREVIOUS_STAGE_PROPERTY]: ['build_a', 'build_b'],
                },
              ],
            },
          ],
        },
      ]);
    });

    it('returns lookup map with correct indices', () => {
      const queryStages = [
        {
          name: 'build',
          groups: {
            nodes: [
              {
                name: 'build_group_1',
                jobs: { nodes: [{ name: 'build_a', [NEEDS_PROPERTY]: { nodes: [] } }] },
              },
              {
                name: 'build_group_2',
                jobs: { nodes: [{ name: 'build_b', [NEEDS_PROPERTY]: { nodes: [] } }] },
              },
            ],
          },
        },
      ];

      const { lookup } = unwrapStagesWithNeedsAndLookup(queryStages);

      expect(lookup).toEqual({
        build_group_1: { stageIdx: 0, groupIdx: 0 },
        build_group_2: { stageIdx: 0, groupIdx: 1 },
      });
    });
  });

  describe('unwrapStagesFromMutation', () => {
    it('correctly extracts all job names from previous stage across multiple groups', () => {
      const mutationStages = [
        {
          name: 'build',
          groups: [
            {
              name: 'build_group_1',
              jobs: [
                { name: 'build_a', [NEEDS_PROPERTY]: [] },
                { name: 'build_b', [NEEDS_PROPERTY]: [] },
              ],
            },
            {
              name: 'build_group_2',
              jobs: [
                { name: 'build_c', [NEEDS_PROPERTY]: [] },
                { name: 'build_d', [NEEDS_PROPERTY]: [] },
              ],
            },
          ],
        },
        {
          name: 'test',
          groups: [
            {
              name: 'test_group',
              jobs: [
                {
                  name: 'test_job',
                  [NEEDS_PROPERTY]: [],
                },
              ],
            },
          ],
        },
      ];

      const result = unwrapStagesFromMutation(mutationStages);

      expect(result).toMatchObject([
        {
          groups: [
            {
              jobs: [
                { [ALL_JOBS_FROM_PREVIOUS_STAGE_PROPERTY]: [] },
                { [ALL_JOBS_FROM_PREVIOUS_STAGE_PROPERTY]: [] },
              ],
            },
            {
              jobs: [
                { [ALL_JOBS_FROM_PREVIOUS_STAGE_PROPERTY]: [] },
                { [ALL_JOBS_FROM_PREVIOUS_STAGE_PROPERTY]: [] },
              ],
            },
          ],
        },
        {
          groups: [
            {
              jobs: [
                {
                  [ALL_JOBS_FROM_PREVIOUS_STAGE_PROPERTY]: [
                    'build_a',
                    'build_b',
                    'build_c',
                    'build_d',
                  ],
                },
              ],
            },
          ],
        },
      ]);
    });

    it('creates union of previous stage jobs and explicit needs with deduplication', () => {
      const mutationStages = [
        {
          name: 'build',
          groups: [
            {
              name: 'build_a',
              jobs: [{ name: 'build_a', [NEEDS_PROPERTY]: [] }],
            },
            {
              name: 'build_b',
              jobs: [{ name: 'build_b', [NEEDS_PROPERTY]: [] }],
            },
          ],
        },
        {
          name: 'test',
          groups: [
            {
              name: 'test_job',
              jobs: [
                {
                  name: 'test_job',
                  [NEEDS_PROPERTY]: [{ name: 'build_a' }],
                },
              ],
            },
          ],
        },
      ];

      const result = unwrapStagesFromMutation(mutationStages);

      expect(result[1].groups[0].jobs[0][NEEDS_PROPERTY]).toEqual(['build_a']);
      expect(result[1].groups[0].jobs[0][ALL_JOBS_FROM_PREVIOUS_STAGE_PROPERTY]).toEqual([
        'build_a',
        'build_b',
      ]);
    });

    it('correctly unwraps needs from [{ name: "job" }] to ["job"]', () => {
      const stagesWithObjectNeeds = [
        {
          name: 'deploy',
          groups: [
            {
              name: 'deploy_job',
              size: 1,
              jobs: [
                {
                  name: 'deploy_job',
                  [NEEDS_PROPERTY]: [
                    { name: 'build_job', __typename: 'CiConfigNeed' },
                    { name: 'test_job', __typename: 'CiConfigNeed' },
                  ],
                },
              ],
            },
          ],
        },
      ];

      const result = unwrapStagesFromMutation(stagesWithObjectNeeds);

      expect(result[0].groups[0].jobs[0][NEEDS_PROPERTY]).toEqual(['build_job', 'test_job']);
    });

    it('handles empty stages array', () => {
      const emptyStages = [];

      const result = unwrapStagesFromMutation(emptyStages);

      expect(result).toEqual([]);
    });

    it('handles stages with missing/undefined groups', () => {
      const stagesWithoutGroups = [
        {
          name: 'build',
        },
        {
          name: 'test',
          groups: undefined,
        },
        {
          name: 'deploy',
          groups: null,
        },
      ];

      const result = unwrapStagesFromMutation(stagesWithoutGroups);

      expect(result).toHaveLength(3);
      expect(result[0].groups).toEqual([]);
      expect(result[1].groups).toEqual([]);
      expect(result[2].groups).toEqual([]);
    });

    it('handles groups with missing/undefined jobs', () => {
      const stagesWithoutJobs = [
        {
          name: 'build',
          groups: [
            {
              name: 'build_group',
              size: 1,
            },
            {
              name: 'test_group',
              size: 1,
              jobs: undefined,
            },
            {
              name: 'deploy_group',
              size: 1,
              jobs: null,
            },
          ],
        },
      ];

      const result = unwrapStagesFromMutation(stagesWithoutJobs);

      expect(result[0].groups).toHaveLength(3);
      expect(result[0].groups[0].jobs).toEqual([]);
      expect(result[0].groups[1].jobs).toEqual([]);
      expect(result[0].groups[2].jobs).toEqual([]);
    });
  });
});
