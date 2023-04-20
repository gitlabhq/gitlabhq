import $ from 'jquery';
import initPopover from '~/blob/suggest_gitlab_ci_yml';
import { createAlert } from '~/alert';
import { setCookie } from '~/lib/utils/common_utils';
import Tracking from '~/tracking';
import NewCommitForm from '../new_commit_form';

const initPopovers = () => {
  const suggestEl = document.querySelector('.js-suggest-gitlab-ci-yml');

  if (suggestEl) {
    const commitButton = document.querySelector('#commit-changes');

    initPopover(suggestEl);

    if (commitButton) {
      const { dismissKey, humanAccess } = suggestEl.dataset;
      const urlParams = new URLSearchParams(window.location.search);
      const mergeRequestPath = urlParams.get('mr_path') || true;

      const commitCookieName = `suggest_gitlab_ci_yml_commit_${dismissKey}`;
      const commitTrackLabel = 'suggest_gitlab_ci_yml_commit_changes';
      const commitTrackValue = '20';

      commitButton.addEventListener('click', () => {
        setCookie(commitCookieName, mergeRequestPath);

        Tracking.event(undefined, 'click_button', {
          label: commitTrackLabel,
          property: humanAccess,
          value: commitTrackValue,
        });
      });
    }
  }
};

export default () => {
  const editBlobForm = $('.js-edit-blob-form');

  if (editBlobForm.length) {
    const urlRoot = editBlobForm.data('relativeUrlRoot');
    const assetsPath = editBlobForm.data('assetsPrefix');
    const filePath = `${editBlobForm.data('blobFilename')}`;
    const currentAction = $('.js-file-title').data('currentAction');
    const projectId = editBlobForm.data('project-id');
    const isMarkdown = editBlobForm.data('is-markdown');
    const previewMarkdownPath = editBlobForm.data('previewMarkdownPath');
    const commitButton = $('.js-commit-button');
    const commitButtonLoading = $('.js-commit-button-loading');
    const cancelLink = $('#cancel-changes');

    import('./edit_blob')
      .then(({ default: EditBlob } = {}) => {
        // eslint-disable-next-line no-new
        new EditBlob({
          assetsPath: `${urlRoot}${assetsPath}`,
          filePath,
          currentAction,
          projectId,
          isMarkdown,
          previewMarkdownPath,
        });
        initPopovers();
      })
      .catch((e) =>
        createAlert({
          message: e.message,
        }),
      );

    cancelLink.on('click', () => {
      window.onbeforeunload = null;
    });

    commitButton.on('click', () => {
      commitButton.addClass('gl-display-none');
      commitButtonLoading.removeClass('gl-display-none');
      window.onbeforeunload = null;
    });

    new NewCommitForm(editBlobForm); // eslint-disable-line no-new

    // returning here blocks page navigation
    window.onbeforeunload = () => '';
  }
};
