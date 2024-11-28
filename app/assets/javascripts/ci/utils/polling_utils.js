import { FOUR_MINUTES_IN_MS, PIPELINE_POLL_INTERVAL_BACKOFF } from '~/ci/constants';

export const getIncreasedPollInterval = (currentInterval) => {
  const intervalIncreased = PIPELINE_POLL_INTERVAL_BACKOFF * currentInterval;

  return intervalIncreased >= FOUR_MINUTES_IN_MS ? FOUR_MINUTES_IN_MS : intervalIncreased;
};
