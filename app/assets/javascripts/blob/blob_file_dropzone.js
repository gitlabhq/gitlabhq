/* eslint-disable func-names, object-shorthand, prefer-arrow-callback */

import $ from 'jquery';
import Dropzone from 'dropzone';
import { visitUrl } from '../lib/utils/url_utility';
import { HIDDEN_CLASS } from '../lib/utils/constants';
import csrf from '../lib/utils/csrf';

Dropzone.autoDiscover = false;

function toggleLoading($el, $icon, loading) {
  if (loading) {
    $el.disable();
    $icon.removeClass(HIDDEN_CLASS);
  } else {
    $el.enable();
    $icon.addClass(HIDDEN_CLASS);
  }
}
export default class BlobFileDropzone {
  constructor(form, method) {
    const formDropzone = form.find('.dropzone');
    const submitButton = form.find('#submit-all');
    const submitButtonLoadingIcon = submitButton.find('.js-loading-icon');
    const dropzoneMessage = form.find('.dz-message');
    Dropzone.autoDiscover = false;

    const dropzone = formDropzone.dropzone({
      autoDiscover: false,
      autoProcessQueue: false,
      url: form.attr('action'),
      // Rails uses a hidden input field for PUT
      // http://stackoverflow.com/questions/21056482/how-to-set-method-put-in-form-tag-in-rails
      method: method,
      clickable: true,
      uploadMultiple: false,
      paramName: 'file',
      maxFilesize: gon.max_file_size || 10,
      parallelUploads: 1,
      maxFiles: 1,
      addRemoveLinks: true,
      previewsContainer: '.dropzone-previews',
      headers: csrf.headers,
      init: function () {
        this.on('addedfile', function () {
          toggleLoading(submitButton, submitButtonLoadingIcon, false);
          dropzoneMessage.addClass(HIDDEN_CLASS);
          $('.dropzone-alerts').html('').hide();
        });
        this.on('removedfile', function () {
          toggleLoading(submitButton, submitButtonLoadingIcon, false);
          dropzoneMessage.removeClass(HIDDEN_CLASS);
        });
        this.on('success', function (header, response) {
          $('#modal-upload-blob').modal('hide');
          visitUrl(response.filePath);
        });
        this.on('maxfilesexceeded', function (file) {
          dropzoneMessage.addClass(HIDDEN_CLASS);
          this.removeFile(file);
        });
        this.on('sending', function (file, xhr, formData) {
          formData.append('branch_name', form.find('.js-branch-name').val());
          formData.append('create_merge_request', form.find('.js-create-merge-request').val());
          formData.append('commit_message', form.find('.js-commit-message').val());
        });
      },
      // Override behavior of adding error underneath preview
      error: function (file, errorMessage) {
        const stripped = $('<div/>').html(errorMessage).text();
        $('.dropzone-alerts').html(`Error uploading file: "${stripped}"`).show();
        this.removeFile(file);
      },
    });

    submitButton.on('click', (e) => {
      e.preventDefault();
      e.stopPropagation();
      if (dropzone[0].dropzone.getQueuedFiles().length === 0) {
        // eslint-disable-next-line no-alert
        alert('Please select a file');
        return false;
      }
      toggleLoading(submitButton, submitButtonLoadingIcon, true);
      dropzone[0].dropzone.processQueue();
      return false;
    });
  }
}
