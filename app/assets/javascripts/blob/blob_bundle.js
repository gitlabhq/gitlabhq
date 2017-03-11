/* eslint-disable no-new */
/* global NewCommitForm */

import EditBlob from './edit_blob';
import BlobFileDropzone from './blob_file_dropzone';

$(() => {
  const editBlobForm = $('.js-edit-blob-form');
  const uploadBlobForm = $('.js-upload-blob-form');

  if (editBlobForm.length) {
    const urlRoot = editBlobForm.data('relative-url-root');
    const assetsPath = editBlobForm.data('assets-prefix');
    const blobLanguage = editBlobForm.data('blob-language');

    new EditBlob(`${urlRoot}${assetsPath}`, blobLanguage);
    new NewCommitForm(editBlobForm);
  }

  if (uploadBlobForm.length) {
    const method = uploadBlobForm.attr('method');

    new BlobFileDropzone(uploadBlobForm, method);
    new NewCommitForm(uploadBlobForm);

    window.gl.utils.disableButtonIfEmptyField(
      uploadBlobForm.find('.js-commit-message'),
      '.btn-upload-file',
    );
  }
});
