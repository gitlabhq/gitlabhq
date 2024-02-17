import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import MrWidgetHowToMergeModal from '~/vue_merge_request_widget/components/mr_widget_how_to_merge_modal.vue';

export default () => {
  const modalEl = document.getElementById('js-check-out-modal');

  if (!modalEl) return false;

  const {
    canMerge,
    isFork,
    sourceBranch,
    sourceProjectPath,
    targetBranch,
    sourceProjectDefaultUrl,
    reviewingDocsPath,
  } = modalEl.dataset;

  return new Vue({
    el: modalEl,
    render(h) {
      return h(MrWidgetHowToMergeModal, {
        props: {
          canMerge: parseBoolean(canMerge),
          isFork: parseBoolean(isFork),
          sourceBranch,
          sourceProjectPath,
          targetBranch,
          sourceProjectDefaultUrl,
          reviewingDocsPath,
        },
      });
    },
  });
};
