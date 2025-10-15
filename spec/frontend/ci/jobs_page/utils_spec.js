import { updateJobsNodes } from '~/ci/jobs_page/utils';
import { mockJobsResponsePaginated } from 'jest/ci/jobs_mock_data';

describe('Jobs utility functions', () => {
  describe('updateJobsNodes', () => {
    it('updates the job status from running to passed', () => {
      const listWithRunningJobs = mockJobsResponsePaginated;
      listWithRunningJobs.data.project.jobs.nodes[0].detailedStatus.text = 'Running';

      const updatedJob = structuredClone(listWithRunningJobs.data.project.jobs.nodes[0]);
      updatedJob.detailedStatus.text = 'Passed';

      const { updatedJobs, processedJobDone } = updateJobsNodes(
        listWithRunningJobs.data.project.jobs.nodes,
        updatedJob,
      );

      expect(updatedJobs).toHaveLength(listWithRunningJobs.data.project.jobs.nodes.length);
      expect(processedJobDone).toBe(true);
      expect(updatedJobs[0].detailedStatus.text).toBe('Passed');
    });

    it('returns processedJobDone as false when the processed job is new', () => {
      const updatedJob = structuredClone(mockJobsResponsePaginated.data.project.jobs.nodes[0]);
      updatedJob.id = 'gid://gitlab/Ci::Build/100';

      const { processedJobDone } = updateJobsNodes(
        mockJobsResponsePaginated.data.project.jobs.nodes,
        updatedJob,
      );

      expect(processedJobDone).toBe(false);
    });
  });
});
