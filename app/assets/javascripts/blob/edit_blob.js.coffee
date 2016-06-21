class @EditBlob
  constructor: (assets_path, ace_mode = null) ->
    ace.config.set "modePath", "#{assets_path}/ace"
    ace.config.loadModule "ace/ext/searchbox"
    @editor = ace.edit("editor")
    @editor.focus()
    @editor.getSession().setMode "ace/mode/#{ace_mode}" if ace_mode

    # Before a form submission, move the content from the Ace editor into the
    # submitted textarea
    $('form').submit =>
      $("#file-content").val(@editor.getValue())

    @initModePanesAndLinks()

    new BlobLicenseSelectors { @editor }
    new BlobGitignoreSelectors { @editor }
    new BlobCiYamlSelectors { @editor }

  initModePanesAndLinks: ->
    @$editModePanes = $(".js-edit-mode-pane")
    @$editModeLinks = $(".js-edit-mode a")
    @$editModeLinks.click @editModeLinkClickHandler

  editModeLinkClickHandler: (event) =>
    event.preventDefault()
    currentLink = $(event.target)
    paneId = currentLink.attr("href")
    currentPane = @$editModePanes.filter(paneId)
    @$editModeLinks.parent().removeClass "active hover"
    currentLink.parent().addClass "active hover"
    @$editModePanes.hide()
    currentPane.fadeIn 200
    if paneId is "#preview"
      $.post currentLink.data("preview-url"),
        content: @editor.getValue()
      , (response) ->
        currentPane.empty().append response
        currentPane.syntaxHighlight()

    else
      @editor.focus()
