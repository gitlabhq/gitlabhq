import { prepareFailedJobs } from '~/pipelines/components/jobs/utils';
import {
  mockFailedJobsData,
  mockFailedJobsSummaryData,
  mockPreparedFailedJobsData,
} from '../../mock_data';

describe('Utils', () => {
  it('prepares failed jobs data correctly', () => {
    expect(prepareFailedJobs(mockFailedJobsData, mockFailedJobsSummaryData)).toEqual(
      mockPreparedFailedJobsData,
    );
  });
});
