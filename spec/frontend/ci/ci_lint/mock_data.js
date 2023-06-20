import { mockJobs } from 'jest/ci/pipeline_editor/mock_data';
import { convertObjectPropsToSnakeCase } from '~/lib/utils/common_utils';

export const mockLintDataError = {
  data: {
    lintCI: {
      errors: ['Error message'],
      warnings: ['Warning message'],
      valid: false,
      jobs: mockJobs.map((j) => {
        const job = { ...j, tags: j.tagList };
        delete job.tagList;
        return job;
      }),
    },
  },
};

export const mockLintDataValid = {
  data: {
    lintCI: {
      errors: [],
      warnings: [],
      valid: true,
      jobs: mockJobs.map((j) => {
        const job = { ...j, tags: j.tagList };
        delete job.tagList;
        return job;
      }),
    },
  },
};

export const mockLintDataErrorRest = {
  ...mockLintDataError.data.lintCI,
  jobs: mockJobs.map((j) => convertObjectPropsToSnakeCase(j)),
};

export const mockLintDataValidRest = {
  ...mockLintDataValid.data.lintCI,
  jobs: mockJobs.map((j) => convertObjectPropsToSnakeCase(j)),
};
