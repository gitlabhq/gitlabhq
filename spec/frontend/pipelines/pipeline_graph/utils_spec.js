import {
  preparePipelineGraphData,
  createUniqueJobId,
  generateJobNeedsDict,
} from '~/pipelines/utils';

describe('utils functions', () => {
  const emptyResponse = { stages: [], jobs: {} };
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

  describe('preparePipelineGraphData', () => {
    describe('returns an empty array of stages and empty job objects if', () => {
      it('no data is passed', () => {
        expect(preparePipelineGraphData({})).toEqual(emptyResponse);
      });

      it('no stages are found', () => {
        expect(preparePipelineGraphData({ includes: 'template/myTemplate.gitlab-ci.yml' })).toEqual(
          emptyResponse,
        );
      });
    });

    describe('returns the correct array of stages and object of jobs', () => {
      it('when multiple jobs are in the same stage', () => {
        const expectedData = {
          stages: [
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
          ],
          jobs: {
            [jobName1]: { ...job1, id: createUniqueJobId(job1.stage, jobName1) },
            [jobName2]: { ...job2, id: createUniqueJobId(job2.stage, jobName2) },
          },
        };
        expect(
          preparePipelineGraphData({ [jobName1]: { ...job1 }, [jobName2]: { ...job2 } }),
        ).toEqual(expectedData);
      });

      it('when stages are defined by the user', () => {
        const userDefinedStage2 = 'myStage2';

        const expectedData = {
          stages: [
            {
              name: userDefinedStage,
              groups: [],
            },
            {
              name: userDefinedStage2,
              groups: [],
            },
          ],
          jobs: {},
        };

        expect(preparePipelineGraphData({ stages: [userDefinedStage, userDefinedStage2] })).toEqual(
          expectedData,
        );
      });

      it('by combining user defined stage and job stages, it preserves user defined order', () => {
        const userDefinedStageThatOverlaps = 'deploy';

        expect(
          preparePipelineGraphData({
            stages: [userDefinedStage, userDefinedStageThatOverlaps],
            [jobName1]: { ...job1 },
            [jobName2]: { ...job2 },
            [jobName3]: { ...job3 },
            [jobName4]: { ...job4 },
          }),
        ).toEqual(pipelineGraphData);
      });

      it('with only unique values', () => {
        const expectedData = {
          stages: [
            {
              name: job1.stage,
              groups: [
                {
                  name: jobName1,
                  jobs: [{ ...job1 }],
                  id: createUniqueJobId(job1.stage, jobName1),
                },
              ],
            },
          ],
          jobs: {
            [jobName1]: { ...job1, id: createUniqueJobId(job1.stage, jobName1) },
          },
        };

        expect(
          preparePipelineGraphData({
            stages: ['build'],
            [jobName1]: { ...job1 },
            [jobName1]: { ...job1 },
          }),
        ).toEqual(expectedData);
      });
    });
  });

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
