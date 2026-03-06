import { pinia } from '~/pinia/instance';
import { RapidDiffsFacade } from '~/rapid_diffs/app';
import { adapters } from '~/rapid_diffs/app/adapter_configs/merge_request';
import { useCodeReview } from '~/diffs/stores/code_review';
import { useMergeRequestDiscussions } from '~/merge_request/stores/merge_request_discussions';

class MergeRequestRapidDiffsApp extends RapidDiffsFacade {
  adapterConfig = adapters;

  async init() {
    this.#initCodeReview();
    super.init();
    await this.#initDiscussions();
  }

  // eslint-disable-next-line class-methods-use-this
  #initDiscussions() {
    return useMergeRequestDiscussions().fetchNotes();
  }

  #initCodeReview() {
    if (!gon.current_user_id) return;
    const { mr_path: mrPath } = JSON.parse(this.root.dataset.appData);
    if (!mrPath) return;

    const store = useCodeReview(pinia);

    store.setMrPath(mrPath);
    store.restoreFromAutosave();
    store.restoreFromLegacyMrReviews();
  }
}

export const createMergeRequestRapidDiffsApp = (options) => {
  return new MergeRequestRapidDiffsApp(options);
};
