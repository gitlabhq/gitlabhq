import { isFailedJob, sortJobsByStatus } from '~/ci/pipelines_page/components/failure_widget/utils';

describe('isFailedJob', () => {
  describe('when the job argument is undefined', () => {
    it('returns false', () => {
      expect(isFailedJob()).toBe(false);
    });
  });

  describe('when the job is of status `failed`', () => {
    it('returns false', () => {
      expect(isFailedJob({ detailedStatus: { group: 'success' } })).toBe(false);
    });
  });

  describe('when the job status is `failed`', () => {
    it('returns true', () => {
      expect(isFailedJob({ detailedStatus: { group: 'failed' } })).toBe(true);
    });
  });
});

describe('sortJobsByStatus', () => {
  describe('when the arg is undefined', () => {
    it('returns an empty array', () => {
      expect(sortJobsByStatus()).toEqual([]);
    });
  });

  describe('when receiving an empty array', () => {
    it('returns an empty array', () => {
      expect(sortJobsByStatus([])).toEqual([]);
    });
  });

  describe('when reciving a list of jobs', () => {
    const jobArr = [
      { detailedStatus: { group: 'failed' } },
      { detailedStatus: { group: 'allowed_to_fail' } },
      { detailedStatus: { group: 'failed' } },
      { detailedStatus: { group: 'success' } },
    ];

    const expectedResult = [
      { detailedStatus: { group: 'failed' } },
      { detailedStatus: { group: 'failed' } },
      { detailedStatus: { group: 'allowed_to_fail' } },
      { detailedStatus: { group: 'success' } },
    ];

    it('sorts failed jobs first', () => {
      expect(sortJobsByStatus(jobArr)).toEqual(expectedResult);
    });
  });
});
