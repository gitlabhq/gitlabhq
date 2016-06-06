((w) ->
  w.gl ?= {}
  w.gl.text ?= {}

  gl.text.randomString = -> Math.random().toString(36).substring(7)

  gl.text.replaceRange = (s, start, end, substitute) ->
    s.substring(0, start) + substitute + s.substring(end);

  gl.text.selectedText = (text, textarea) ->
    text.substring(textarea.selectionStart, textarea.selectionEnd)

  gl.text.insertText = (textArea, text, tag, selected, wrap) ->
    startChar = if not wrap and textArea.selectionStart > 0 then '\n' else ''
    insertText = "#{startChar}#{tag}#{selected}#{if wrap then tag else ' '}"

    if document.queryCommandSupported('insertText')
      document.execCommand 'insertText', false, insertText
    else
      try
        document.execCommand("ms-beginUndoUnit")

      textArea.value = @replaceRange(
          text,
          textArea.selectionStart,
          textArea.selectionEnd,
          insertText)
      try
        document.execCommand("ms-endUndoUnit")

    @moveCursor(textArea, tag, wrap)

  gl.text.moveCursor = (textArea, tag, wrapped) ->
    return unless textArea.setSelectionRange

    if textArea.selectionStart is textArea.selectionEnd
      if wrapped
        pos = textArea.selectionStart - tag.length
      else
        pos = textArea.selectionStart

      textArea.setSelectionRange pos, pos

  gl.text.updateText = (textArea, tag, wrap) ->
    $textArea = $(textArea)
    oldVal = $textArea.val()
    textArea = $textArea.get(0)
    text = $textArea.val()
    selected = @selectedText(text, textArea)
    $textArea.focus()

    @insertText(textArea, text, tag, selected, wrap)

  gl.text.addListeners = ->
    self = @
    $('.js-md').on 'click', ->
      $this = $(@)
      self.updateText(
        $this.closest('.md-area').find('textarea'),
        $this.data('md-tag'),
        not $this.data('md-prepend')
      )

  gl.text.removeListeners = ->
    $('.js-md').off()

) window
