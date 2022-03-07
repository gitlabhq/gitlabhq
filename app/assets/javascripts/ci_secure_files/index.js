import Vue from 'vue';
import SecureFilesList from './components/secure_files_list.vue';

export const initCiSecureFiles = (selector = '#js-ci-secure-files') => {
  const containerEl = document.querySelector(selector);
  const { projectId } = containerEl.dataset;

  return new Vue({
    el: containerEl,
    provide: {
      projectId,
    },
    render(createElement) {
      return createElement(SecureFilesList);
    },
  });
};
