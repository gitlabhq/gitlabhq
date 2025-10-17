import { RapidDiffsFacade } from '~/rapid_diffs/app';
import { adapters } from '~/rapid_diffs/app/adapter_configs/commit';

class CommitRapidDiffsApp extends RapidDiffsFacade {
  adapterConfig = adapters;
}

export const createCommitRapidDiffsApp = (options) => {
  return new CommitRapidDiffsApp(options);
};
