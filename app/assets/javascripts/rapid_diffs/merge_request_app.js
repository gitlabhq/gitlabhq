import { RapidDiffsFacade } from '~/rapid_diffs/app';
import { adapters } from '~/rapid_diffs/app/adapter_configs/merge_request';

class MergeRequestRapidDiffsApp extends RapidDiffsFacade {
  adapterConfig = adapters;
}

export const createMergeRequestRapidDiffsApp = (options) => {
  return new MergeRequestRapidDiffsApp(options);
};
