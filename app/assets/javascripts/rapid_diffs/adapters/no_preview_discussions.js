import { watch } from 'vue';
import { MOUNTED } from '~/rapid_diffs/adapter_events';
import { createAlert, VARIANT_INFO } from '~/alert';
import { n__, sprintf } from '~/locale';
import { isFileDiscussion } from '~/rapid_diffs/utils/discussion_position';

export const createNoPreviewDiscussionsAdapter = (store) => ({
  [MOUNTED](addCleanup) {
    const { diffElement } = this;
    const { oldPath, newPath } = this.data;
    let alert = null;

    const stopWatcher = watch(
      () =>
        store
          .findDiscussionsForFile({ oldPath, newPath })
          .filter((discussion) => !isFileDiscussion(discussion)),
      (lineDiscussions) => {
        alert?.dismiss();
        alert = null;
        if (lineDiscussions.length === 0) return;
        alert = createAlert({
          message: sprintf(
            n__(
              'RapidDiffs|%{count} thread hidden.',
              'RapidDiffs|%{count} threads hidden.',
              lineDiscussions.length,
            ),
            { count: lineDiscussions.length },
          ),
          variant: VARIANT_INFO,
          parent: diffElement,
          dismissible: false,
        });
      },
      { immediate: true },
    );

    addCleanup(() => {
      stopWatcher();
      alert?.dismiss();
      alert = null;
    });
  },
});
