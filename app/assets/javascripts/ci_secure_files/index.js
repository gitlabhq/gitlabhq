import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import SecureFilesList from './components/secure_files_list.vue';

export const initCiSecureFiles = (selector = '#js-ci-secure-files') => {
  const containerEl = document.querySelector(selector);

  if (!containerEl) {
    return false;
  }

  const { projectId } = containerEl.dataset;
  const { admin } = containerEl.dataset;
  const { fileSizeLimit } = containerEl.dataset;

  return new Vue({
    el: containerEl,
    provide: {
      projectId,
      admin: parseBoolean(admin),
      fileSizeLimit,
    },
    render(createElement) {
      return createElement(SecureFilesList);
    },
  });
};
