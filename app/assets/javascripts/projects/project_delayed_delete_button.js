import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import ProjectDelayedDeleteButton from './components/project_delayed_delete_button.vue';

export default (selector = '#js-project-delayed-delete-button') => {
  const el = document.querySelector(selector);

  if (!el) return;

  const {
    delayedDeletionDate,
    confirmPhrase,
    nameWithNamespace,
    formPath,
    restoreHelpPath,
    isFork,
    issuesCount,
    mergeRequestsCount,
    forksCount,
    starsCount,
    buttonText,
  } = el.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    render(createElement) {
      return createElement(ProjectDelayedDeleteButton, {
        props: {
          delayedDeletionDate,
          confirmPhrase,
          nameWithNamespace,
          formPath,
          restoreHelpPath,
          isFork: parseBoolean(isFork),
          issuesCount: parseInt(issuesCount, 10),
          mergeRequestsCount: parseInt(mergeRequestsCount, 10),
          forksCount: parseInt(forksCount, 10),
          starsCount: parseInt(starsCount, 10),
          buttonText,
        },
      });
    },
  });
};
