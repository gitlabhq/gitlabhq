import { mockJobs } from 'jest/pipeline_editor/mock_data';

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
