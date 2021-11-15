import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import ProjectDeleteButton from './components/project_delete_button.vue';

export default (selector = '#js-project-delete-button') => {
  const el = document.querySelector(selector);

  if (!el) return;

  const {
    confirmPhrase,
    formPath,
    isFork,
    issuesCount,
    mergeRequestsCount,
    forksCount,
    starsCount,
  } = el.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    render(createElement) {
      return createElement(ProjectDeleteButton, {
        props: {
          confirmPhrase,
          formPath,
          isFork: parseBoolean(isFork),
          issuesCount: parseInt(issuesCount, 10),
          mergeRequestsCount: parseInt(mergeRequestsCount, 10),
          forksCount: parseInt(forksCount, 10),
          starsCount: parseInt(starsCount, 10),
        },
      });
    },
  });
};
