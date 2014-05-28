$(document).ready ->
  alertClass = "alert alert-danger alert-dismissable div-dropzone-alert"
  alertAttr = "class=\"close\" data-dismiss=\"alert\"" + "aria-hidden=\"true\""
  divHover = "<div class=\"div-dropzone-hover\"></div>"
  divSpinner = "<div class=\"div-dropzone-spinner\"></div>"
  divAlert = "<div class=\"" + alertClass + "\"></div>"
  iconPicture = "<i class=\"icon-picture div-dropzone-icon\"></i>"
  iconSpinner = "<i class=\"icon-spinner icon-spin div-dropzone-icon\"></i>"
  btnAlert = "<button type=\"button\"" + alertAttr + ">&times;</button>"
  project_image_path_upload = window.project_image_path_upload or null

  $("textarea.markdown-area").wrap "<div class=\"div-dropzone\"></div>"  
  $(".div-dropzone").parent().addClass "div-dropzone-wrapper"
  $(".div-dropzone").append divHover
  $(".div-dropzone-hover").append iconPicture
  $(".div-dropzone").append divSpinner 
  $(".div-dropzone-spinner").append iconSpinner

  dropzone = $(".div-dropzone").dropzone(
    url: project_image_path_upload
    dictDefaultMessage: ""
    clickable: true
    paramName: "markdown_img"
    maxFilesize: 10
    uploadMultiple: false
    acceptedFiles: "image/jpg,image/jpeg,image/gif,image/png"
    headers: 
      "X-CSRF-Token": $("meta[name=\"csrf-token\"]").attr("content")

    previewContainer: false

    processing: ->
      closeAlertMessage()

    dragover: ->
      $(".div-dropzone > textarea").addClass "div-dropzone-focus"
      $(".div-dropzone-hover").css "opacity", 0.7
      return

    dragleave: ->
      $(".div-dropzone > textarea").removeClass "div-dropzone-focus"
      $(".div-dropzone-hover").css "opacity", 0
      return

    drop: ->
      $(".div-dropzone > textarea").removeClass "div-dropzone-focus"
      $(".div-dropzone-hover").css "opacity", 0
      $(".div-dropzone > textarea").focus()
      return

    success: (header, response) ->
      appendToTextArea(formatLink(response.link))
      return

    error: (temp, errorMessage) ->
      showError(errorMessage)
      return

    sending: ->
      showSpinner()
      return

    complete: ->
      $(".dz-preview").remove()
      $(".markdown-area").trigger "input"
      closeSpinner()
      return
  )

  child = $(dropzone[0]).children("textarea")

  formatLink = (str) ->
    "![" + str.alt + "](" + str.url + ")"

  handlePaste = (e) ->
    e.preventDefault()
    my_event = e.originalEvent
    
    if my_event.clipboardData and my_event.clipboardData.items
      i = 0
      while i < my_event.clipboardData.items.length
        item = my_event.clipboardData.items[i]
        processItem(my_event, item)
        i++

  processItem = (e, item) ->
    if isImage(item)
      filename = getFilename(e) or "image.png"
      text = "{{" + filename + "}}"
      pasteText(text)
      uploadFile item.getAsFile(), filename
    else if e.clipboardData.items.length == 1
      text = e.clipboardData.getData("text/plain")
      pasteText(text)

  isImage = (item) ->
    if item
      item.type.indexOf("image") isnt -1

  pasteText = (text) ->
    caretStart = $(child)[0].selectionStart
    caretEnd = $(child)[0].selectionEnd
    textEnd = $(child).val().length

    beforeSelection = $(child).val().substring 0, caretStart
    afterSelection = $(child).val().substring caretEnd, textEnd
    $(child).val beforeSelection + text + afterSelection
    $(".markdown-area").trigger "input"

  getFilename = (e) -> 
    if window.clipboardData and window.clipboardData.getData
      value = window.clipboardData.getData("Text")
    else if e.clipboardData and e.clipboardData.getData
      value = e.clipboardData.getData("text/plain")
    
    value = value.split("\r")
    value.first()

  uploadFile = (item, filename) ->
    formData = new FormData()
    formData.append "markdown_img", item, filename
    $.ajax
      url: project_image_path_upload
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
    $(".div-dropzone-spinner").css "opacity", 0.7

  closeSpinner = ->
    $(".div-dropzone-spinner").css "opacity", 0

  showError = (message) ->
    checkIfMsgExists = $(".error-alert").children().length
    if checkIfMsgExists is 0
      $(".error-alert").append divAlert
      $(".div-dropzone-alert").append btnAlert + message

  closeAlertMessage = ->
    $(".div-dropzone-alert").alert "close"

  $(".markdown-selector").click (e) ->
    e.preventDefault()
    $(".div-dropzone").click()
    return

  $(".div-dropzone").on "paste", handlePaste

  return