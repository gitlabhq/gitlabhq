/* eslint-disable no-new */

import $ from 'jquery';
import NewCommitForm from '../new_commit_form';
import EditBlob from './edit_blob';
import BlobFileDropzone from '../blob/blob_file_dropzone';

export default () => {
  const editBlobForm = $('.js-edit-blob-form');
  const uploadBlobForm = $('.js-upload-blob-form');
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

    window.gl.utils.disableButtonIfEmptyField(
      uploadBlobForm.find('.js-commit-message'),
      '.btn-upload-file',
    );
  }

  if (deleteBlobForm.length) {
    new NewCommitForm(deleteBlobForm);
  }
};
