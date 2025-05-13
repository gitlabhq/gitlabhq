import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import MrWidgetHowToMergeModal from '~/vue_merge_request_widget/components/mr_widget_how_to_merge_modal.vue';

export default () => {
  const modalEl = document.getElementById('js-check-out-modal');

  if (!modalEl) return false;

  const { isFork, sourceBranch, sourceProjectPath, sourceProjectDefaultUrl, reviewingDocsPath } =
    modalEl.dataset;

  return new Vue({
    el: modalEl,
    render(h) {
      return h(MrWidgetHowToMergeModal, {
        props: {
          isFork: parseBoolean(isFork),
          sourceBranch,
          sourceProjectPath,
          sourceProjectDefaultUrl,
          reviewingDocsPath,
        },
      });
    },
  });
};
