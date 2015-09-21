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

      init: ->
        this.on 'addedfile', (file) ->
          $('.dropzone-alerts').html('').hide()
          commit_message = form.find('#commit_message')[0]

          if /^Upload/.test(commit_message.placeholder)
            commit_message.placeholder = 'Upload ' + file.name

          return

        this.on 'removedfile', (file) ->
          commit_message = form.find('#commit_message')[0]

          if /^Upload/.test(commit_message.placeholder)
            commit_message.placeholder = 'Upload new file'

          return

        this.on 'success', (header, response) ->
          window.location.href = response.filePath
          return

        this.on 'maxfilesexceeded', (file) ->
          @removeFile file
          return

        this.on 'sending', (file, xhr, formData) ->
          formData.append('commit_message', form.find('#commit_message').val())
          return

      # Override behavior of adding error underneath preview
      error: (file, errorMessage) ->
        stripped = $("<div/>").html(errorMessage).text();
        $('.dropzone-alerts').html('Error uploading file: \"' + stripped + '\"').show()
        @removeFile file
        return
    )

    submitButton = form.find('#submit-all')[0]
    submitButton.addEventListener 'click', (e) ->
      e.preventDefault()
      e.stopPropagation()
      alert "Please select a file" if dropzone[0].dropzone.getQueuedFiles().length == 0
      dropzone[0].dropzone.processQueue()
      return false
