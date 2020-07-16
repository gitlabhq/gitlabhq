/* eslint-disable no-new */

import $ from 'jquery';
import NewCommitForm from '../new_commit_form';
import EditBlob from './edit_blob';
import BlobFileDropzone from '../blob/blob_file_dropzone';
import initPopover from '~/blob/suggest_gitlab_ci_yml';
import { disableButtonIfEmptyField, setCookie } from '~/lib/utils/common_utils';
import Tracking from '~/tracking';

export default () => {
  const editBlobForm = $('.js-edit-blob-form');
  const uploadBlobForm = $('.js-upload-blob-form');
  const deleteBlobForm = $('.js-delete-blob-form');
  const suggestEl = document.querySelector('.js-suggest-gitlab-ci-yml');

  if (editBlobForm.length) {
    const urlRoot = editBlobForm.data('relativeUrlRoot');
    const assetsPath = editBlobForm.data('assetsPrefix');
    const filePath = `${editBlobForm.data('blobFilename')}`;
    const currentAction = $('.js-file-title').data('currentAction');
    const projectId = editBlobForm.data('project-id');
    const isMarkdown = editBlobForm.data('is-markdown');
    const commitButton = $('.js-commit-button');
    const cancelLink = $('.btn.btn-cancel');

    cancelLink.on('click', () => {
      window.onbeforeunload = null;
    });

    commitButton.on('click', () => {
      window.onbeforeunload = null;
    });

    new EditBlob({
      assetsPath: `${urlRoot}${assetsPath}`,
      filePath,
      currentAction,
      projectId,
      isMarkdown,
    });
    new NewCommitForm(editBlobForm);

    // returning here blocks page navigation
    window.onbeforeunload = () => '';
  }

  if (uploadBlobForm.length) {
    const method = uploadBlobForm.data('method');

    new BlobFileDropzone(uploadBlobForm, method);
    new NewCommitForm(uploadBlobForm);

    disableButtonIfEmptyField(uploadBlobForm.find('.js-commit-message'), '.btn-upload-file');
  }

  if (deleteBlobForm.length) {
    new NewCommitForm(deleteBlobForm);
  }

  if (suggestEl) {
    const commitButton = document.querySelector('#commit-changes');

    initPopover(suggestEl);

    if (commitButton) {
      const { dismissKey, humanAccess } = suggestEl.dataset;
      const commitCookieName = `suggest_gitlab_ci_yml_commit_${dismissKey}`;
      const commitTrackLabel = 'suggest_gitlab_ci_yml_commit_changes';
      const commitTrackValue = '20';

      commitButton.addEventListener('click', () => {
        setCookie(commitCookieName, true);

        Tracking.event(undefined, 'click_button', {
          label: commitTrackLabel,
          property: humanAccess,
          value: commitTrackValue,
        });
      });
    }
  }
};
