import { createUniqueJobId, generateJobNeedsDict } from '~/pipelines/utils';

describe('utils functions', () => {
  const jobName1 = 'build_1';
  const jobName2 = 'build_2';
  const jobName3 = 'test_1';
  const jobName4 = 'deploy_1';
  const job1 = { script: 'echo hello', stage: 'build' };
  const job2 = { script: 'echo build', stage: 'build' };
  const job3 = { script: 'echo test', stage: 'test', needs: [jobName1, jobName2] };
  const job4 = { script: 'echo deploy', stage: 'deploy', needs: [jobName3] };
  const userDefinedStage = 'myStage';

  const pipelineGraphData = {
    stages: [
      {
        name: userDefinedStage,
        groups: [],
      },
      {
        name: job4.stage,
        groups: [
          {
            name: jobName4,
            jobs: [{ ...job4 }],
            id: createUniqueJobId(job4.stage, jobName4),
          },
        ],
      },
      {
        name: job1.stage,
        groups: [
          {
            name: jobName1,
            jobs: [{ ...job1 }],
            id: createUniqueJobId(job1.stage, jobName1),
          },
          {
            name: jobName2,
            jobs: [{ ...job2 }],
            id: createUniqueJobId(job2.stage, jobName2),
          },
        ],
      },
      {
        name: job3.stage,
        groups: [
          {
            name: jobName3,
            jobs: [{ ...job3 }],
            id: createUniqueJobId(job3.stage, jobName3),
          },
        ],
      },
    ],
    jobs: {
      [jobName1]: { ...job1, id: createUniqueJobId(job1.stage, jobName1) },
      [jobName2]: { ...job2, id: createUniqueJobId(job2.stage, jobName2) },
      [jobName3]: { ...job3, id: createUniqueJobId(job3.stage, jobName3) },
      [jobName4]: { ...job4, id: createUniqueJobId(job4.stage, jobName4) },
    },
  };

  describe('generateJobNeedsDict', () => {
    it('generates an empty object if it receives no jobs', () => {
      expect(generateJobNeedsDict({ jobs: {} })).toEqual({});
    });

    it('generates a dict with empty needs if there are no dependencies', () => {
      const smallGraph = {
        jobs: {
          [jobName1]: { ...job1, id: createUniqueJobId(job1.stage, jobName1) },
          [jobName2]: { ...job2, id: createUniqueJobId(job2.stage, jobName2) },
        },
      };

      expect(generateJobNeedsDict(smallGraph)).toEqual({
        [pipelineGraphData.jobs[jobName1].id]: [],
        [pipelineGraphData.jobs[jobName2].id]: [],
      });
    });

    it('generates a dict where key is the a job and its value is an array of all its needs', () => {
      const uniqueJobName1 = pipelineGraphData.jobs[jobName1].id;
      const uniqueJobName2 = pipelineGraphData.jobs[jobName2].id;
      const uniqueJobName3 = pipelineGraphData.jobs[jobName3].id;
      const uniqueJobName4 = pipelineGraphData.jobs[jobName4].id;

      expect(generateJobNeedsDict(pipelineGraphData)).toEqual({
        [uniqueJobName1]: [],
        [uniqueJobName2]: [],
        [uniqueJobName3]: [uniqueJobName1, uniqueJobName2],
        [uniqueJobName4]: [uniqueJobName3, uniqueJobName1, uniqueJobName2],
      });
    });
  });
});
