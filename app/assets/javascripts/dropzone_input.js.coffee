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
    btnAlert = "<button type=\"button\"" + alertAttr + ">&times;</button>"
    project_uploads_path = window.project_uploads_path or null

    form_textarea = $(form).find("textarea.markdown-area")
    form_textarea.wrap "<div class=\"div-dropzone\"></div>"
    form_textarea.bind 'paste', (event) =>
      handlePaste(event)

    form_dropzone = $(form).find('.div-dropzone')
    form_dropzone.parent().addClass "div-dropzone-wrapper"
    form_dropzone.append divHover
    $(".div-dropzone-hover").append iconPaperclip
    form_dropzone.append divSpinner
    $(".div-dropzone-spinner").append iconSpinner
    $(".div-dropzone-spinner").css
      "opacity": 0
      "display": "none"

    # Preview button
    $(document).off "click", ".js-md-preview-button"
    $(document).on "click", ".js-md-preview-button", (e) ->
      ###
      Shows the Markdown preview.

      Lets the server render GFM into Html and displays it.
      ###
      e.preventDefault()
      form = $(this).closest("form")
      # toggle tabs
      form.find(".js-md-write-button").parent().removeClass "active"
      form.find(".js-md-preview-button").parent().addClass "active"

      # toggle content
      form.find(".md-write-holder").hide()
      form.find(".md-preview-holder").show()

      preview = form.find(".js-md-preview")
      mdText = form.find(".markdown-area").val()
      if mdText.trim().length is 0
        preview.text "Nothing to preview."
      else
        preview.text "Loading..."
        $.post($(this).data("url"),
          md_text: mdText
        ).success (previewData) ->
          preview.html previewData

    # Write button
    $(document).off "click", ".js-md-write-button"
    $(document).on "click", ".js-md-write-button", (e) ->
      ###
      Shows the Markdown textarea.
      ###
      e.preventDefault()
      form = $(this).closest("form")
      # toggle tabs
      form.find(".js-md-write-button").parent().addClass "active"
      form.find(".js-md-preview-button").parent().removeClass "active"

      # toggle content
      form.find(".md-write-holder").show()
      form.find(".md-preview-holder").hide()

    dropzone = form_dropzone.dropzone(
      url: project_uploads_path
      dictDefaultMessage: ""
      clickable: true
      paramName: "file"
      maxFilesize: 10
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
        child = $(dropzone[0]).children("textarea")
        $(child).val $(child).val() + formatLink(response.link) + "\n"
        return

      error: (temp, errorMessage) ->
        checkIfMsgExists = $(".error-alert").children().length
        if checkIfMsgExists is 0
          $(".error-alert").append divAlert
          $(".div-dropzone-alert").append btnAlert + errorMessage
        return

      sending: ->
        form_dropzone.find(".div-dropzone-spinner").css
          "opacity": 0.7
          "display": "inherit"
        return

      complete: ->
        $(".dz-preview").remove()
        $(".markdown-area").trigger "input"
        $(".div-dropzone-spinner").css
          "opacity": 0
          "display": "none"
        return
    )

    child = $(dropzone[0]).children("textarea")

    formatLink = (link) ->
      text = "[#{link.alt}](#{link.url})"
      text = "!#{text}" if link.is_image
      text

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
          insertToTextArea(filename, formatLink(response.responseJSON.link))

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
      checkIfMsgExists = $(".error-alert").children().length
      if checkIfMsgExists is 0
        $(".error-alert").append divAlert
        $(".div-dropzone-alert").append btnAlert + message

    closeAlertMessage = ->
      form.find(".div-dropzone-alert").alert "close"

    form.find(".markdown-selector").click (e) ->
      e.preventDefault()
      $(@).closest('.gfm-form').find('.div-dropzone').click()
      return

  formatLink: (link) ->
    text = "[#{link.alt}](#{link.url})"
    text = "!#{text}" if link.is_image
    text