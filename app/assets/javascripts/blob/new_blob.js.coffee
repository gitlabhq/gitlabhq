class @NewBlob
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

    # Before a form submission, move the content from the Ace editor into the
    # submitted textarea
    $('form').submit ->
      $("#file-content").val(editor.getValue())

  editor: ->
    return @editor
