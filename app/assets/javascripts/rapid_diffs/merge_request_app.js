import { watch } from 'vue';
import { pinia } from '~/pinia/instance';
import { createAlert } from '~/alert';
import { __ } from '~/locale';
import { RapidDiffsFacade } from '~/rapid_diffs/app';
import { adapters } from '~/rapid_diffs/app/adapter_configs/merge_request';
import { useCodeReview } from '~/diffs/stores/code_review';
import { useMergeRequestDiscussions } from '~/merge_request/stores/merge_request_discussions';
import { useDiffsList } from '~/rapid_diffs/stores/diffs_list';
import { DiffFile } from '~/rapid_diffs/web_components/diff_file';
import { initCommitWidget } from '~/rapid_diffs/app/init_commit_widget';
import { initCompareVersions } from '~/rapid_diffs/app/init_compare_versions';
import { initNewDiscussionToggle } from '~/rapid_diffs/app/init_new_discussions_toggle';
import { initLineRangeSelection } from '~/rapid_diffs/app/init_line_range_selection';

class MergeRequestRapidDiffsApp extends RapidDiffsFacade {
  adapterConfig = adapters;

  async init() {
    this.#initCodeReview();
    super.init();
    this.#initCompareVersions();
    this.#initCommitWidget();
    await this.#initDiscussions();
    initNewDiscussionToggle(this.root, { allowExpandedLines: true });
    initLineRangeSelection(this.root);
  }

  // eslint-disable-next-line class-methods-use-this
  scrollToDiffNote(discussion) {
    const store = useDiffsList(pinia);
    const position = discussion.position || discussion.original_position;
    const endLine = position.line_range?.end || position;

    let stop;

    const handler = () => {
      const diffFile = DiffFile.getAll().find(
        (file) =>
          file.data.oldPath === position.old_path && file.data.newPath === position.new_path,
      );
      if (diffFile) {
        diffFile.selectLine(endLine.old_line, endLine.new_line);
        useMergeRequestDiscussions(pinia).expandDiscussion(discussion);
        stop?.();
      } else if (store.status === 'idle' || store.status === 'error') {
        stop?.();
      }
    };

    stop = watch(() => store.loadedFiles, handler, { immediate: true });
  }

  // eslint-disable-next-line class-methods-use-this
  setLinkedFile(position) {
    useDiffsList(pinia).setLinkedFileData({
      old_path: position.old_path,
      new_path: position.new_path,
    });
  }

  // eslint-disable-next-line class-methods-use-this
  #initDiscussions() {
    return useMergeRequestDiscussions(pinia)
      .fetchNotesAndDrafts()
      .catch((error) => {
        createAlert({
          message: __('An error occurred while loading comments'),
          captureError: true,
          error,
        });
      });
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

  #initCompareVersions() {
    if (!this.appData.versions) return;
    initCompareVersions(this.root.querySelector('[data-after-browser-toggle]'), this.appData);
  }

  #initCommitWidget() {
    initCommitWidget(this.root.querySelector('[data-commit-widget]'));
  }
}

export const createMergeRequestRapidDiffsApp = (options) => {
  return new MergeRequestRapidDiffsApp(options);
};
