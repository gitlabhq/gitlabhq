import {
  normalizeDownstreamPipelines,
  normalizeStages,
  sortJobsByStatus,
} from '~/ci/pipeline_mini_graph/utils/data_utils';

const graphqlDownstream = [
  {
    __typename: 'CiPipeline',
    id: 'gid://gitlab/Ci::Pipeline/2',
    iid: 234,
    path: '/pipeline/path',
    detailedStatus: {
      __typename: 'DetailedStatus',
      icon: 'status_success',
      label: 'passed',
      tooltip: 'passed',
    },
    project: {
      name: 'project name',
      fullPath: 'full/path',
    },
  },
];

const restDownstream = [
  {
    id: 4,
    iid: 234,
    details: {
      status: {
        icon: 'status_success',
        label: 'passed',
        tooltip: 'passed',
      },
    },
    path: 'project/path',
    project: {
      name: 'downstream project',
      full_path: '/full/path',
    },
  },
];

const graphqlStage = [
  {
    __typename: 'CiStage',
    id: 'gid://gitlab/Ci::Stage/2',
    name: 'deploy',
    detailedStatus: {
      __typename: 'DetailedStatus',
      icon: 'status_success',
      label: 'passed',
      tooltip: 'passed',
    },
  },
];

const restStage = [
  {
    id: 2,
    name: 'deploy',
    status: {
      icon: 'status_success',
      label: 'passed',
      tooltip: 'passed',
    },
  },
];

describe('Data utils', () => {
  describe('stages', () => {
    it('Does not normalize GraphQL stages', () => {
      expect(normalizeStages(graphqlStage)).toEqual(graphqlStage);
    });

    it('normalizes REST stages', () => {
      expect(normalizeStages(restStage)).toEqual([
        {
          id: 'gid://gitlab/Ci::Stage/2',
          detailedStatus: {
            icon: 'status_success',
            label: 'passed',
            tooltip: 'passed',
          },
          name: 'deploy',
        },
      ]);
    });
  });

  describe('downstream pipelines', () => {
    it('Does not normalize GraphQL pipelines', () => {
      expect(normalizeDownstreamPipelines(graphqlDownstream)).toEqual(graphqlDownstream);
    });

    it('normalizes REST pipelines', () => {
      expect(normalizeDownstreamPipelines(restDownstream)).toEqual([
        {
          id: 'gid://gitlab/Ci::Pipeline/4',
          iid: 234,
          detailedStatus: {
            icon: 'status_success',
            label: 'passed',
            tooltip: 'passed',
          },
          path: 'project/path',
          project: {
            name: 'downstream project',
            fullPath: 'full/path',
          },
        },
      ]);
    });
  });

  describe('sortJobsByStatus', () => {
    const createJob = (group) => ({
      detailedStatus: { group },
    });

    it('sorts jobs by status order: failed > manual > other > success', () => {
      const jobs = [
        createJob('success'),
        createJob('manual'),
        createJob('failed'),
        createJob(undefined),
        createJob('running'),
        createJob('failed'),
      ];

      const sortedJobs = sortJobsByStatus(jobs);

      expect(sortedJobs.map((job) => job.detailedStatus.group)).toStrictEqual([
        'failed',
        'failed',
        'manual',
        undefined,
        'running',
        'success',
      ]);
    });

    it('returns empty array when jobs is undefined', () => {
      expect(sortJobsByStatus(undefined)).toStrictEqual([]);
    });
  });
});
