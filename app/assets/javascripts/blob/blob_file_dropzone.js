/* eslint-disable */
(function() {
  this.BlobFileDropzone = (function() {
    function BlobFileDropzone(form, method) {
      var dropzone, form_dropzone, submitButton;
      form_dropzone = form.find('.dropzone');
      Dropzone.autoDiscover = false;
      dropzone = form_dropzone.dropzone({
        autoDiscover: false,
        autoProcessQueue: false,
        url: form.attr('action'),
        // Rails uses a hidden input field for PUT
        // http://stackoverflow.com/questions/21056482/how-to-set-method-put-in-form-tag-in-rails
        method: method,
        clickable: true,
        uploadMultiple: false,
        paramName: "file",
        maxFilesize: gon.max_file_size || 10,
        parallelUploads: 1,
        maxFiles: 1,
        addRemoveLinks: true,
        previewsContainer: '.dropzone-previews',
        headers: {
          "X-CSRF-Token": $("meta[name=\"csrf-token\"]").attr("content")
        },
        init: function() {
          this.on('addedfile', function(file) {
            $('.dropzone-alerts').html('').hide();
          });
          this.on('success', function(header, response) {
            window.location.href = response.filePath;
          });
          this.on('maxfilesexceeded', function(file) {
            this.removeFile(file);
          });
          return this.on('sending', function(file, xhr, formData) {
            formData.append('target_branch', form.find('.js-target-branch').val());
            formData.append('create_merge_request', form.find('.js-create-merge-request').val());
            formData.append('commit_message', form.find('.js-commit-message').val());
          });
        },
        // Override behavior of adding error underneath preview
        error: function(file, errorMessage) {
          var stripped;
          stripped = $("<div/>").html(errorMessage).text();
          $('.dropzone-alerts').html('Error uploading file: \"' + stripped + '\"').show();
          this.removeFile(file);
        }
      });
      submitButton = form.find('#submit-all')[0];
      submitButton.addEventListener('click', function(e) {
        e.preventDefault();
        e.stopPropagation();
        if (dropzone[0].dropzone.getQueuedFiles().length === 0) {
          alert("Please select a file");
        }
        dropzone[0].dropzone.processQueue();
        return false;
      });
    }

    return BlobFileDropzone;

  })();

}).call(this);
