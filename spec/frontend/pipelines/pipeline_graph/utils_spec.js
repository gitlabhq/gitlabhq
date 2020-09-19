import { preparePipelineGraphData } from '~/pipelines/utils';

describe('preparePipelineGraphData', () => {
  const emptyResponse = { stages: [] };
  const jobName1 = 'build_1';
  const jobName2 = 'build_2';
  const jobName3 = 'test_1';
  const jobName4 = 'deploy_1';
  const job1 = { [jobName1]: { script: 'echo hello', stage: 'build' } };
  const job2 = { [jobName2]: { script: 'echo build', stage: 'build' } };
  const job3 = { [jobName3]: { script: 'echo test', stage: 'test' } };
  const job4 = { [jobName4]: { script: 'echo deploy', stage: 'deploy' } };

  describe('returns an object with an empty array of stages if', () => {
    it('no data is passed', () => {
      expect(preparePipelineGraphData({})).toEqual(emptyResponse);
    });

    it('no stages are found', () => {
      expect(preparePipelineGraphData({ includes: 'template/myTemplate.gitlab-ci.yml' })).toEqual(
        emptyResponse,
      );
    });
  });

  describe('returns the correct array of stages', () => {
    it('when multiple jobs are in the same stage', () => {
      const expectedData = {
        stages: [
          {
            name: job1[jobName1].stage,
            groups: [
              {
                name: jobName1,
                jobs: [{ script: job1[jobName1].script, stage: job1[jobName1].stage }],
              },
              {
                name: jobName2,
                jobs: [{ script: job2[jobName2].script, stage: job2[jobName2].stage }],
              },
            ],
          },
        ],
      };

      expect(preparePipelineGraphData({ ...job1, ...job2 })).toEqual(expectedData);
    });

    it('when stages are defined by the user', () => {
      const userDefinedStage = 'myStage';
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
      };

      expect(preparePipelineGraphData({ stages: [userDefinedStage, userDefinedStage2] })).toEqual(
        expectedData,
      );
    });

    it('by combining user defined stage and job stages, it preserves user defined order', () => {
      const userDefinedStage = 'myStage';
      const userDefinedStageThatOverlaps = 'deploy';

      const expectedData = {
        stages: [
          {
            name: userDefinedStage,
            groups: [],
          },
          {
            name: job4[jobName4].stage,
            groups: [
              {
                name: jobName4,
                jobs: [{ script: job4[jobName4].script, stage: job4[jobName4].stage }],
              },
            ],
          },
          {
            name: job1[jobName1].stage,
            groups: [
              {
                name: jobName1,
                jobs: [{ script: job1[jobName1].script, stage: job1[jobName1].stage }],
              },
              {
                name: jobName2,
                jobs: [{ script: job2[jobName2].script, stage: job2[jobName2].stage }],
              },
            ],
          },
          {
            name: job3[jobName3].stage,
            groups: [
              {
                name: jobName3,
                jobs: [{ script: job3[jobName3].script, stage: job3[jobName3].stage }],
              },
            ],
          },
        ],
      };

      expect(
        preparePipelineGraphData({
          stages: [userDefinedStage, userDefinedStageThatOverlaps],
          ...job1,
          ...job2,
          ...job3,
          ...job4,
        }),
      ).toEqual(expectedData);
    });

    it('with only unique values', () => {
      const expectedData = {
        stages: [
          {
            name: job1[jobName1].stage,
            groups: [
              {
                name: jobName1,
                jobs: [{ script: job1[jobName1].script, stage: job1[jobName1].stage }],
              },
            ],
          },
        ],
      };

      expect(
        preparePipelineGraphData({
          stages: ['build'],
          ...job1,
          ...job1,
        }),
      ).toEqual(expectedData);
    });
  });
});
