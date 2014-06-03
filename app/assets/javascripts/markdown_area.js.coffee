formatLink = (str) ->
  "![" + str.alt + "](" + str.url + ")"

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
      $(".div-dropzone-alert").alert "close"

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
      $(".div-dropzone-spinner").css "opacity", 0.7
      return

    complete: ->
      $(".dz-preview").remove()
      $(".markdown-area").trigger "input"
      $(".div-dropzone-spinner").css "opacity", 0
      return
  )

  $(".markdown-selector").click (e) ->
    e.preventDefault()
    $(".div-dropzone").click()
    return

  return