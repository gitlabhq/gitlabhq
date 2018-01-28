/* eslint-disable func-names, space-before-function-paren, prefer-arrow-callback, no-var, quotes, vars-on-top, no-unused-vars, no-new, max-len */
/* global EditBlob */
import NewCommitForm from '../new_commit_form';
import EditBlob from './edit_blob';
import BlobFileDropzone from '../blob/blob_file_dropzone';

$(() => {
  const editBlobForm = $('.js-edit-blob-form');
  const uploadBlobForm = $('.js-upload-blob-form');
  const deleteBlobForm = $('.js-delete-blob-form');

  if (editBlobForm.length) {
    const urlRoot = editBlobForm.data('relative-url-root');
    const assetsPath = editBlobForm.data('assets-prefix');
    const blobLanguage = editBlobForm.data('blob-language');
    const currentAction = $('.js-file-title').data('current-action');

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
});
