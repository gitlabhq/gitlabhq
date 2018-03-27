/* eslint-disable func-names, space-before-function-paren, prefer-arrow-callback, no-var, quotes, vars-on-top, no-unused-vars, no-new, max-len */
/* global EditBlob */

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
    const blobLanguage = editBlobForm.data('blobLanguage');
    const currentAction = $('.js-file-title').data('currentAction');

    new EditBlob(`${urlRoot}${assetsPath}`, blobLanguage, currentAction);
    new NewCommitForm(editBlobForm);
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
