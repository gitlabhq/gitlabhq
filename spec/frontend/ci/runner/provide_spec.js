import { runnersAppProvide } from '~/ci/runner/provide';

import { runnerInstallHelpPage } from 'jest/ci/runner/mock_data';
import { ONLINE_CONTACT_TIMEOUT_SECS, STALE_TIMEOUT_SECS } from '~/ci/runner/constants';

const mockDataset = {
  runnerInstallHelpPage,
  onlineContactTimeoutSecs: `${ONLINE_CONTACT_TIMEOUT_SECS}`,
  staleTimeoutSecs: `${STALE_TIMEOUT_SECS}`,
};

describe('admin runners provide', () => {
  it('returns provide values', () => {
    expect(runnersAppProvide(mockDataset)).toMatchObject({
      runnerInstallHelpPage,
      onlineContactTimeoutSecs: ONLINE_CONTACT_TIMEOUT_SECS,
      staleTimeoutSecs: STALE_TIMEOUT_SECS,
    });
  });

  it('returns only provide values', () => {
    const dataset = {
      ...mockDataset,
      extraEntry: 'ANOTHER_ENTRY',
    };

    expect(runnersAppProvide(dataset)).not.toMatchObject({
      extraEntry: 'ANOTHER_ENTRY',
    });
  });
});
