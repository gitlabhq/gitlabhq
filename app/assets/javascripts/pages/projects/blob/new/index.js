import initBlobBundle from '~/blob_edit/blob_bundle';
import initPopover from '~/blob/suggest_gitlab_ci_yml';

document.addEventListener('DOMContentLoaded', () => {
  initBlobBundle();

  const suggestEl = document.querySelector('.js-suggest-gitlab-ci-yml');

  if (suggestEl) {
    initPopover(suggestEl);
  }
});
