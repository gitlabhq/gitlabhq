import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import MrWidgetHowToMergeModal from '~/vue_merge_request_widget/components/mr_widget_how_to_merge_modal.vue';

let modalRoot;

function ensureModalRoot(appData) {
  if (modalRoot) return modalRoot;

  const el = document.createElement('div');
  document.body.appendChild(el);

  modalRoot = new Vue({
    name: 'RapidDiffsHowToMergeModalRoot',
    render(h) {
      return h(MrWidgetHowToMergeModal, {
        ref: 'modal',
        props: {
          isFork: parseBoolean(appData.isFork),
          sourceBranch: appData.sourceBranch,
          sourceProjectPath: appData.sourceProjectPath,
          sourceProjectDefaultUrl: appData.sourceProjectDefaultUrl,
          reviewingDocsPath: appData.reviewingDocsPath,
        },
      });
    },
  }).$mount(el);

  return modalRoot;
}

export const resolveConflictsLocallyAdapter = {
  clicks: {
    resolveConflictsLocally() {
      ensureModalRoot(this.appData).$refs.modal.$refs.modal.show();
    },
  },
};
