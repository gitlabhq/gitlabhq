import { RapidDiffsFacade } from '~/rapid_diffs/app';
import { adapters } from '~/rapid_diffs/app/adapter_configs/commit';
import { useDiffDiscussions } from '~/rapid_diffs/stores/diff_discussions';
import { pinia } from '~/pinia/instance';
import axios from '~/lib/utils/axios_utils';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';

class CommitRapidDiffsApp extends RapidDiffsFacade {
  adapterConfig = adapters;

  async initDiscussions() {
    try {
      const {
        data: { discussions },
      } = await axios.get(this.appData.discussionsEndpoint);
      useDiffDiscussions(pinia).setInitialDiscussions(discussions);
    } catch (error) {
      createAlert({
        message: s__('RapidDiffs|Failed to load discussions. Try to reload the page.'),
        error,
      });
    }
  }
}

export const createCommitRapidDiffsApp = (options) => {
  return new CommitRapidDiffsApp(options);
};
