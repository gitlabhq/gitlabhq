#= require markdown_preview

class @DropzoneInput
  constructor: (form) ->
    Dropzone.autoDiscover = false
    alertClass = "alert alert-danger alert-dismissable div-dropzone-alert"
    alertAttr = "class=\"close\" data-dismiss=\"alert\"" + "aria-hidden=\"true\""
    divHover = "<div class=\"div-dropzone-hover\"></div>"
    divSpinner = "<div class=\"div-dropzone-spinner\"></div>"
    divAlert = "<div class=\"" + alertClass + "\"></div>"
    iconPaperclip = "<i class=\"fa fa-paperclip div-dropzone-icon\"></i>"
    iconSpinner = "<i class=\"fa fa-spinner fa-spin div-dropzone-icon\"></i>"
    uploadProgress = $("<div class=\"div-dropzone-progress\"></div>")
    btnAlert = "<button type=\"button\"" + alertAttr + ">&times;</button>"
    project_uploads_path = window.project_uploads_path or null
    max_file_size = gon.max_file_size or 10

    form_textarea = $(form).find("textarea.markdown-area")
    form_textarea.wrap "<div class=\"div-dropzone\"></div>"
    form_textarea.on 'paste', (event) =>
      handlePaste(event)

    $(form).setupMarkdownPreview()

    form_dropzone = $(form).find('.div-dropzone')
    form_dropzone.parent().addClass "div-dropzone-wrapper"
    form_dropzone.append divHover
    form_dropzone.find(".div-dropzone-hover").append iconPaperclip
    form_dropzone.append divSpinner
    form_dropzone.find(".div-dropzone-spinner").append iconSpinner
    form_dropzone.find(".div-dropzone-spinner").append uploadProgress
    form_dropzone.find(".div-dropzone-spinner").css
      "opacity": 0
      "display": "none"

    dropzone = form_dropzone.dropzone(
      url: project_uploads_path
      dictDefaultMessage: ""
      clickable: true
      paramName: "file"
      maxFilesize: max_file_size
      uploadMultiple: false
      headers:
        "X-CSRF-Token": $("meta[name=\"csrf-token\"]").attr("content")

      previewContainer: false

      processing: ->
        $(".div-dropzone-alert").alert "close"

      dragover: ->
        form_textarea.addClass "div-dropzone-focus"
        form.find(".div-dropzone-hover").css "opacity", 0.7
        return

      dragleave: ->
        form_textarea.removeClass "div-dropzone-focus"
        form.find(".div-dropzone-hover").css "opacity", 0
        return

      drop: ->
        form_textarea.removeClass "div-dropzone-focus"
        form.find(".div-dropzone-hover").css "opacity", 0
        form_textarea.focus()
        return

      success: (header, response) ->
        pasteText response.link.markdown
        return

      error: (temp, errorMessage) ->
        errorAlert = $(form).find('.error-alert')
        checkIfMsgExists = errorAlert.children().length
        if checkIfMsgExists is 0
          errorAlert.append divAlert
          $(".div-dropzone-alert").append btnAlert + errorMessage
        return

      totaluploadprogress: (totalUploadProgress) ->
        uploadProgress.text Math.round(totalUploadProgress) + "%"
        return

      sending: ->
        form_dropzone.find(".div-dropzone-spinner").css
          "opacity": 0.7
          "display": "inherit"
        return

      queuecomplete: ->
        uploadProgress.text ""
        $(".dz-preview").remove()
        $(".markdown-area").trigger "input"
        $(".div-dropzone-spinner").css
          "opacity": 0
          "display": "none"
        return
    )

    child = $(dropzone[0]).children("textarea")

    handlePaste = (event) ->
      pasteEvent = event.originalEvent
      if pasteEvent.clipboardData and pasteEvent.clipboardData.items
        image = isImage(pasteEvent)
        if image
          event.preventDefault()

          filename = getFilename(pasteEvent) or "image.png"
          text = "{{" + filename + "}}"
          pasteText(text)
          uploadFile image.getAsFile(), filename

    isImage = (data) ->
      i = 0
      while i < data.clipboardData.items.length
        item = data.clipboardData.items[i]
        if item.type.indexOf("image") isnt -1
          return item
        i++
      return false

    pasteText = (text) ->
      caretStart = $(child)[0].selectionStart
      caretEnd = $(child)[0].selectionEnd
      textEnd = $(child).val().length

      beforeSelection = $(child).val().substring 0, caretStart
      afterSelection = $(child).val().substring caretEnd, textEnd
      $(child).val beforeSelection + text + afterSelection
      child.get(0).setSelectionRange caretStart + text.length, caretEnd + text.length
      form_textarea.trigger "input"

    getFilename = (e) ->
      if window.clipboardData and window.clipboardData.getData
        value = window.clipboardData.getData("Text")
      else if e.clipboardData and e.clipboardData.getData
        value = e.clipboardData.getData("text/plain")

      value = value.split("\r")
      value.first()

    uploadFile = (item, filename) ->
      formData = new FormData()
      formData.append "file", item, filename
      $.ajax
        url: project_uploads_path
        type: "POST"
        data: formData
        dataType: "json"
        processData: false
        contentType: false
        headers:
          "X-CSRF-Token": $("meta[name=\"csrf-token\"]").attr("content")

        beforeSend: ->
          showSpinner()
          closeAlertMessage()

        success: (e, textStatus, response) ->
          insertToTextArea(filename, response.responseJSON.link.markdown)

        error: (response) ->
          showError(response.responseJSON.message)

        complete: ->
          closeSpinner()

    insertToTextArea = (filename, url) ->
      $(child).val (index, val) ->
        val.replace("{{" + filename + "}}", url + "\n")

    appendToTextArea = (url) ->
      $(child).val (index, val) ->
        val + url + "\n"

    showSpinner = (e) ->
      form.find(".div-dropzone-spinner").css
        "opacity": 0.7
        "display": "inherit"

    closeSpinner = ->
      form.find(".div-dropzone-spinner").css
        "opacity": 0
        "display": "none"

    showError = (message) ->
      errorAlert = $(form).find('.error-alert')
      checkIfMsgExists = errorAlert.children().length
      if checkIfMsgExists is 0
        errorAlert.append divAlert
        $(".div-dropzone-alert").append btnAlert + message

    closeAlertMessage = ->
      form.find(".div-dropzone-alert").alert "close"

    form.find(".markdown-selector").click (e) ->
      e.preventDefault()
      $(@).closest('.gfm-form').find('.div-dropzone').click()
      return
