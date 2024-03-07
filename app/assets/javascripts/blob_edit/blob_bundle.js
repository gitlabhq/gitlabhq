import $ from 'jquery';
import { createAlert } from '~/alert';
import NewCommitForm from '../new_commit_form';

export default () => {
  const editBlobForm = $('.js-edit-blob-form');

  if (editBlobForm.length) {
    const urlRoot = editBlobForm.data('relativeUrlRoot');
    const assetsPath = editBlobForm.data('assetsPrefix');
    const filePath = editBlobForm.data('blobFilename') && `${editBlobForm.data('blobFilename')}`;
    const currentAction = $('.js-file-title').data('currentAction');
    const projectId = editBlobForm.data('project-id');
    const projectPath = editBlobForm.data('project-path');
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
          projectPath,
          isMarkdown,
          previewMarkdownPath,
        });
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
