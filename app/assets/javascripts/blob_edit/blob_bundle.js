/* eslint-disable no-new */

import $ from 'jquery';
import initPopover from '~/blob/suggest_gitlab_ci_yml';
import initCodeQualityWalkthrough from '~/code_quality_walkthrough';
import createFlash from '~/flash';
import { disableButtonIfEmptyField, setCookie } from '~/lib/utils/common_utils';
import Tracking from '~/tracking';
import BlobFileDropzone from '../blob/blob_file_dropzone';
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

const initCodeQualityWalkthroughStep = () => {
  const codeQualityWalkthroughEl = document.querySelector('.js-code-quality-walkthrough');
  if (codeQualityWalkthroughEl) {
    initCodeQualityWalkthrough(codeQualityWalkthroughEl);
  }
};

export const initUploadForm = () => {
  const uploadBlobForm = $('.js-upload-blob-form');
  if (uploadBlobForm.length) {
    const method = uploadBlobForm.data('method');

    new BlobFileDropzone(uploadBlobForm, method);
    new NewCommitForm(uploadBlobForm);

    disableButtonIfEmptyField(uploadBlobForm.find('.js-commit-message'), '.btn-upload-file');
  }
};

export default () => {
  const editBlobForm = $('.js-edit-blob-form');
  const deleteBlobForm = $('.js-delete-blob-form');

  if (editBlobForm.length) {
    const urlRoot = editBlobForm.data('relativeUrlRoot');
    const assetsPath = editBlobForm.data('assetsPrefix');
    const filePath = `${editBlobForm.data('blobFilename')}`;
    const currentAction = $('.js-file-title').data('currentAction');
    const projectId = editBlobForm.data('project-id');
    const isMarkdown = editBlobForm.data('is-markdown');
    const commitButton = $('.js-commit-button');
    const cancelLink = $('.btn.btn-cancel');

    import('./edit_blob')
      .then(({ default: EditBlob } = {}) => {
        new EditBlob({
          assetsPath: `${urlRoot}${assetsPath}`,
          filePath,
          currentAction,
          projectId,
          isMarkdown,
        });
        initPopovers();
        initCodeQualityWalkthroughStep();
      })
      .catch((e) =>
        createFlash({
          message: e,
        }),
      );

    cancelLink.on('click', () => {
      window.onbeforeunload = null;
    });

    commitButton.on('click', () => {
      window.onbeforeunload = null;
    });

    new NewCommitForm(editBlobForm);

    // returning here blocks page navigation
    window.onbeforeunload = () => '';
  }

  initUploadForm();

  if (deleteBlobForm.length) {
    new NewCommitForm(deleteBlobForm);
  }
};
