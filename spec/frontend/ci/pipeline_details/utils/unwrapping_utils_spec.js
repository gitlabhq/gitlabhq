import {
  unwrapGroups,
  unwrapNodesWithName,
  unwrapJobWithNeeds,
  unwrapStagesFromMutation,
} from '~/ci/pipeline_details/utils/unwrapping_utils';
import {
  NEEDS_PROPERTY,
  PREVIOUS_STAGE_JOBS_PROPERTY,
  PREVIOUS_STAGE_JOBS_UNION_NEEDS_PROPERTY,
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
    describe('PREVIOUS_STAGE_JOBS_UNION_NEEDS_PROPERTY addition', () => {
      it('correctly adds PREVIOUS_STAGE_JOBS_UNION_NEEDS_PROPERTY to each job', () => {
        const jobArray = [
          {
            name: 'job_a',
            [PREVIOUS_STAGE_JOBS_PROPERTY]: { nodes: [{ name: 'dep_a' }] },
            [NEEDS_PROPERTY]: { nodes: [{ name: 'dep_b' }] },
          },
          {
            name: 'job_b',
            [PREVIOUS_STAGE_JOBS_PROPERTY]: { nodes: [{ name: 'dep_c' }] },
            [NEEDS_PROPERTY]: { nodes: [] },
          },
        ];

        const result = unwrapJobWithNeeds(jobArray);

        expect(result).toHaveLength(2);
        expect(result[0]).toHaveProperty(PREVIOUS_STAGE_JOBS_UNION_NEEDS_PROPERTY);
        expect(result[1]).toHaveProperty(PREVIOUS_STAGE_JOBS_UNION_NEEDS_PROPERTY);
        expect(result[0][PREVIOUS_STAGE_JOBS_PROPERTY]).toEqual(['dep_a']);
        expect(result[0][NEEDS_PROPERTY]).toEqual(['dep_b']);
        expect(result[0][PREVIOUS_STAGE_JOBS_UNION_NEEDS_PROPERTY]).toEqual(['dep_a', 'dep_b']);
        expect(result[1][PREVIOUS_STAGE_JOBS_PROPERTY]).toEqual(['dep_c']);
        expect(result[1][NEEDS_PROPERTY]).toEqual([]);
        expect(result[1][PREVIOUS_STAGE_JOBS_UNION_NEEDS_PROPERTY]).toEqual(['dep_c']);
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
          [PREVIOUS_STAGE_JOBS_PROPERTY]: { nodes: [{ name: 'stage_dep' }] },
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
            [PREVIOUS_STAGE_JOBS_PROPERTY]: { nodes: [] },
            [NEEDS_PROPERTY]: { nodes: [] },
          },
          {
            name: 'second_job',
            [PREVIOUS_STAGE_JOBS_PROPERTY]: { nodes: [] },
            [NEEDS_PROPERTY]: { nodes: [] },
          },
          {
            name: 'third_job',
            [PREVIOUS_STAGE_JOBS_PROPERTY]: { nodes: [] },
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

  describe('unwrapStagesFromMutation', () => {
    it('transforms valid stages/groups/jobs structure from mutation format', () => {
      const mutationStages = [
        {
          name: 'build',
          groups: [
            {
              name: 'build_job',
              size: 1,
              jobs: [
                {
                  name: 'build_job',
                  script: ['echo "build"'],
                  [NEEDS_PROPERTY]: [],
                },
              ],
            },
          ],
        },
        {
          name: 'test',
          groups: [
            {
              name: 'test_job',
              size: 1,
              jobs: [
                {
                  name: 'test_job',
                  script: ['echo "test"'],
                  [NEEDS_PROPERTY]: [{ name: 'build_job' }],
                },
              ],
            },
          ],
        },
      ];

      const result = unwrapStagesFromMutation(mutationStages);

      expect(result).toHaveLength(2);
      expect(result[0].name).toBe('build');
      expect(result[1].name).toBe('test');
      expect(result[0].groups[0].jobs[0][NEEDS_PROPERTY]).toEqual([]);
      expect(result[1].groups[0].jobs[0][NEEDS_PROPERTY]).toEqual(['build_job']);
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
