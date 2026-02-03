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
import { initTimeline } from '~/rapid_diffs/app/init_timeline';
import TaskList from '~/task_list';
import { UPDATE_COMMENT_FORM } from '~/notes/i18n';

class CommitRapidDiffsApp extends RapidDiffsFacade {
  adapterConfig = adapters;

  async init() {
    super.init();
    this.#initViewModeResize();
    await this.#initDiscussions();
  }

  /**
   * Adjusts the diffs container width when switching between inline and side-by-side view modes.
   *
   * Listens for view type changes via the diffs store and toggles the `container-limited` class
   * on the diffs container. Side-by-side/parallel view always renders full-width for diffs,
   * no matter user preferences (fluid/fixed width). So we do NOT toggle the class.
   */
  // eslint-disable-next-line class-methods-use-this
  #initViewModeResize() {
    useDiffsView().$onAction(({ name }) => {
      if (name !== 'updateViewType') return;
      const diffsContainer = document.querySelector('.js-fixed-layout');
      if (!diffsContainer) return;
      diffsContainer.classList.toggle(
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
      initTimeline(this.appData);
      // eslint-disable-next-line no-new
      new TaskList({
        dataType: 'note',
        fieldName: 'note',
        selector: '[data-rapid-diffs]',
        onSuccess: ({ id, note }) => {
          useDiffDiscussions(pinia).updateNoteTextById(id, note);
        },
        onError: (error) => {
          createAlert({
            message: UPDATE_COMMENT_FORM.defaultError,
            error,
          });
        },
      });
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
