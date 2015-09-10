class @BlobFileDropzone
  constructor: (form, method) ->
    form_dropzone = form.find('.dropzone')
    Dropzone.autoDiscover = false
    dropzone = form_dropzone.dropzone(
      autoDiscover: false
      autoProcessQueue: false
      url: form.attr('action')
      # Rails uses a hidden input field for PUT
      # http://stackoverflow.com/questions/21056482/how-to-set-method-put-in-form-tag-in-rails
      method: method
      clickable: true
      uploadMultiple: false
      paramName: "file"
      maxFilesize: gon.max_file_size or 10
      parallelUploads: 1
      maxFiles: 1
      addRemoveLinks: true
      previewsContainer: '.dropzone-previews'
      headers:
        "X-CSRF-Token": $("meta[name=\"csrf-token\"]").attr("content")

      success: (header, response) ->
        window.location.href = response.filePath
        return

      error: (temp, errorMessage) ->
        stripped = $("<div/>").html(errorMessage).text();
        $('.dropzone-alerts').html('Error uploading file: \"' + stripped + '\"').show()
        return

      maxfilesexceeded: (file) ->
        @removeFile file
        return

      removedfile: (file) ->
        $('.dropzone-previews')[0].removeChild(file.previewTemplate)
        $('.dropzone-alerts').html('').hide()
        return true

      sending: (file, xhr, formData) ->
        formData.append('commit_message', form.find('#commit_message').val())
        return
    )

    submitButton = form.find('#submit-all')[0]
    submitButton.addEventListener 'click', (e) ->
      e.preventDefault()
      e.stopPropagation()
      alert "Please select a file" if dropzone[0].dropzone.getQueuedFiles().length == 0
      dropzone[0].dropzone.processQueue()
      return false
