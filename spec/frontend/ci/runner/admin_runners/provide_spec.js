import { provide } from '~/ci/runner/admin_runners/provide';

import {
  onlineContactTimeoutSecs,
  staleTimeoutSecs,
  runnerInstallHelpPage,
} from 'jest/ci/runner/mock_data';

const mockDataset = {
  runnerInstallHelpPage,
  onlineContactTimeoutSecs,
  staleTimeoutSecs,
};

describe('admin runners provide', () => {
  it('returns provide values', () => {
    expect(provide(mockDataset)).toMatchObject({
      runnerInstallHelpPage,
      onlineContactTimeoutSecs,
      staleTimeoutSecs,
    });
  });

  it('returns only provide values', () => {
    const dataset = {
      ...mockDataset,
      extraEntry: 'ANOTHER_ENTRY',
    };

    expect(provide(dataset)).not.toMatchObject({
      extraEntry: 'ANOTHER_ENTRY',
    });
  });
});
