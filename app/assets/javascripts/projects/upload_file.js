import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { parseBoolean } from '~/lib/utils/common_utils';
import createRouter from '~/repository/router';
import UploadButton from './details/upload_button.vue';

export const initUploadFileTrigger = () => {
  const uploadFileTriggerEl = document.querySelector('.js-upload-file-trigger');

  if (!uploadFileTriggerEl) return false;

  const {
    targetBranch,
    originalBranch,
    canPushCode,
    canPushToBranch,
    path,
    projectPath,
    fullName,
  } = uploadFileTriggerEl.dataset;

  return initVueApp({
    el: uploadFileTriggerEl,
    name: 'UploadButtonRoot',
    router: createRouter(projectPath, originalBranch, fullName),
    provide: {
      targetBranch,
      originalBranch,
      canPushCode: parseBoolean(canPushCode),
      canPushToBranch: parseBoolean(canPushToBranch),
      path,
      emptyRepo: true,
    },
    component: UploadButton,
  });
};
