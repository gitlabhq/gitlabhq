/* eslint-disable no-new */
/* global NewCommitForm */

import EditBlob from './edit_blob';

$(() => {
  const editBlobForm = $('.js-edit-blob-form');
  const urlRoot = editBlobForm.data('relative-url-root');
  const assetsPath = editBlobForm.data('assets-prefix');
  const blobLanguage = editBlobForm.data('blob-language');

  new EditBlob(`${urlRoot}${assetsPath}`, blobLanguage);
  new NewCommitForm(editBlobForm);
});
