import { pinia } from '~/pinia/instance';
import { RapidDiffsFacade } from '~/rapid_diffs/app';
import { adapters } from '~/rapid_diffs/app/adapter_configs/commit';
import { useDiffDiscussions } from '~/rapid_diffs/stores/diff_discussions';
import axios from '~/lib/utils/axios_utils';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import { initNewDiscussionToggle } from '~/rapid_diffs/app/init_new_discussions_toggle';
import { useDiffsView } from '~/rapid_diffs/stores/diffs_view';
import { INLINE_DIFF_VIEW_TYPE } from '~/diffs/constants';

class CommitRapidDiffsApp extends RapidDiffsFacade {
  adapterConfig = adapters;

  async init() {
    super.init();
    this.#initViewModeResize();
    await this.#initDiscussions();
  }

  // eslint-disable-next-line class-methods-use-this
  #initViewModeResize() {
    useDiffsView().$onAction(({ name }) => {
      if (name !== 'updateViewType') return;
      const container = document.querySelector('main .container-fluid');
      if (!container) return;
      container.classList.toggle(
        'container-limited',
        useDiffsView().viewType !== INLINE_DIFF_VIEW_TYPE,
      );
    });
  }

  async #initDiscussions() {
    try {
      const {
        data: { discussions },
      } = await axios.get(this.appData.discussionsEndpoint);
      useDiffDiscussions(pinia).setInitialDiscussions(discussions);
      initNewDiscussionToggle(this.root);
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
