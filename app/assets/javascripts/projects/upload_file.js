import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import createRouter from '~/repository/router';
import UploadButton from './details/upload_button.vue';

export const initUploadFileTrigger = () => {
  const uploadFileTriggerEl = document.querySelector('.js-upload-file-trigger');

  if (!uploadFileTriggerEl) return false;

  const { targetBranch, originalBranch, canPushCode, canPushToBranch, path, projectPath } =
    uploadFileTriggerEl.dataset;

  return new Vue({
    el: uploadFileTriggerEl,
    router: createRouter(projectPath, originalBranch),
    provide: {
      targetBranch,
      originalBranch,
      canPushCode: parseBoolean(canPushCode),
      canPushToBranch: parseBoolean(canPushToBranch),
      path,
      projectPath,
      emptyRepo: true,
    },
    render(h) {
      return h(UploadButton);
    },
  });
};
