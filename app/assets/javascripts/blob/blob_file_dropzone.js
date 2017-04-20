/* eslint-disable func-names, object-shorthand, prefer-arrow-callback */
/* global Dropzone */

export default class BlobFileDropzone {
  constructor(form, method) {
    const formDropzone = form.find('.dropzone');
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
      headers: {
        'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content'),
      },
      init: function () {
        this.on('addedfile', function () {
          $('.dropzone-alerts').html('').hide();
        });
        this.on('success', function (header, response) {
          window.location.href = response.filePath;
        });
        this.on('maxfilesexceeded', function (file) {
          this.removeFile(file);
        });
        this.on('sending', function (file, xhr, formData) {
          formData.append('branch_name', form.find('input[name="branch_name"]').val());
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

    const submitButton = form.find('#submit-all')[0];
    submitButton.addEventListener('click', function (e) {
      e.preventDefault();
      e.stopPropagation();
      if (dropzone[0].dropzone.getQueuedFiles().length === 0) {
        // eslint-disable-next-line no-alert
        alert('Please select a file');
      }
      dropzone[0].dropzone.processQueue();
      return false;
    });
  }
}
