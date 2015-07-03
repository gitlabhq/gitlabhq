class @EditBlob
  constructor: (assets_path, mode)->
    ace.config.set "modePath", assets_path + '/ace'
    ace.config.loadModule "ace/ext/searchbox"
    if mode
      ace_mode = mode
    editor = ace.edit("editor")
    editor.focus()
    @editor = editor

    if ace_mode
      editor.getSession().setMode "ace/mode/" + ace_mode

    $(".js-commit-button").click ->
      $("#file-content").val editor.getValue()
      $(".file-editor form").submit()
      return false

    editModePanes = $(".js-edit-mode-pane")
    editModeLinks = $(".js-edit-mode a")
    editModeLinks.click (event) ->
      event.preventDefault()
      currentLink = $(this)
      paneId = currentLink.attr("href")
      currentPane = editModePanes.filter(paneId)
      editModeLinks.parent().removeClass "active hover"
      currentLink.parent().addClass "active hover"
      editModePanes.hide()
      if paneId is "#preview"
        currentPane.fadeIn 200
        $.post currentLink.data("preview-url"),
          content: editor.getValue()
        , (response) ->
          currentPane.empty().append response
          return

      else
        currentPane.fadeIn 200
        editor.focus()
      return

  editor: ->
    return @editor
