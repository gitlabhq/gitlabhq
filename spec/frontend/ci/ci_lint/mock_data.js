import { mockJobs } from 'jest/ci/pipeline_editor/mock_data';

export const mockLintDataError = {
  data: {
    lintCI: {
      errors: ['Error message'],
      warnings: ['Warning message'],
      valid: false,
      jobs: mockJobs,
    },
  },
};

export const mockLintDataValid = {
  data: {
    lintCI: {
      errors: [],
      warnings: [],
      valid: true,
      jobs: mockJobs,
    },
  },
};
