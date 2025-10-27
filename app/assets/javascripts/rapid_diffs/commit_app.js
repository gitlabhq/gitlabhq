import { RapidDiffsFacade } from '~/rapid_diffs/app';
import { adapters } from '~/rapid_diffs/app/adapter_configs/commit';
import { useDiffDiscussions } from '~/rapid_diffs/stores/diff_discussions';
import { pinia } from '~/pinia/instance';

class CommitRapidDiffsApp extends RapidDiffsFacade {
  adapterConfig = adapters;

  fetchDiscussions() {
    return useDiffDiscussions(pinia).fetchDiscussions(this.appData.discussionsEndpoint);
  }
}

export const createCommitRapidDiffsApp = (options) => {
  return new CommitRapidDiffsApp(options);
};
