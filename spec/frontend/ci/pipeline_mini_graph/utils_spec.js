import { normalizeDownstreamPipelines, normalizeStages } from '~/ci/pipeline_mini_graph/utils';

const graphqlDownstream = [
  {
    __typename: 'CiPipeline',
    id: 'gid://gitlab/Ci::Pipeline/2',
    path: '/pipeline/path',
    detailedStatus: {
      __typename: 'DetailedStatus',
      icon: 'status_success',
      label: 'passed',
      tooltip: 'passed',
    },
    project: {
      name: 'project name',
    },
  },
];

const restDownstream = [
  {
    id: 4,
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

describe('Utils', () => {
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
          detailedStatus: {
            icon: 'status_success',
            label: 'passed',
            tooltip: 'passed',
          },
          path: 'project/path',
          project: {
            name: 'downstream project',
          },
        },
      ]);
    });
  });
});
