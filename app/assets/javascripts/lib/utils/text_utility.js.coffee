((w) ->
  w.gl ?= {}
  w.gl.text ?= {}

  gl.text.randomString = -> Math.random().toString(36).substring(7)

  gl.text.replaceRange = (s, start, end, substitute) ->
    s.substring(0, start) + substitute + s.substring(end);

  gl.text.selectedText = (text, textarea) ->
    text.substring(textarea.selectionStart, textarea.selectionEnd)

  gl.text.lineBefore = (text, textarea) ->
    split = text.substring(0, textarea.selectionStart).trim().split('\n')
    split[split.length - 1]

  gl.text.lineAfter = (text, textarea) ->
    text.substring(textarea.selectionEnd).trim().split('\n')[0]

  gl.text.blockTagText = (text, textArea, blockTag, selected) ->
    lineBefore = @lineBefore(text, textArea)
    lineAfter = @lineAfter(text, textArea)

    if lineBefore is blockTag and lineAfter is blockTag
      # To remove the block tag we have to select the line before & after
      if blockTag?
        textArea.selectionStart = textArea.selectionStart - (blockTag.length + 1)
        textArea.selectionEnd = textArea.selectionEnd + (blockTag.length + 1)

      selected
    else
      "#{blockTag}\n#{selected}\n#{blockTag}"

  gl.text.insertText = (textArea, text, tag, blockTag, selected, wrap) ->
    selectedSplit = selected.split('\n')
    startChar = if not wrap and textArea.selectionStart > 0 then '\n' else ''

    if selectedSplit.length > 1 and (not wrap or blockTag?)
      if blockTag?
        insertText = @blockTagText(text, textArea, blockTag, selected)
      else
        insertText = selectedSplit.map((val) ->
          if val.indexOf(tag) is 0
            "#{val.replace(tag, '')}"
          else
            "#{tag}#{val}"
        ).join('\n')
    else
      insertText = "#{startChar}#{tag}#{selected}#{if wrap then tag else ' '}"

    if document.queryCommandSupported('insertText')
      inserted = document.execCommand 'insertText', false, insertText

    unless inserted
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

  gl.text.updateText = (textArea, tag, blockTag, wrap) ->
    $textArea = $(textArea)
    oldVal = $textArea.val()
    textArea = $textArea.get(0)
    text = $textArea.val()
    selected = @selectedText(text, textArea)
    $textArea.focus()

    @insertText(textArea, text, tag, blockTag, selected, wrap)

  gl.text.init = (form) ->
    self = @
    $('.js-md', form)
      .off 'click'
      .on 'click', ->
        $this = $(@)
        self.updateText(
          $this.closest('.md-area').find('textarea'),
          $this.data('md-tag'),
          $this.data('md-block'),
          not $this.data('md-prepend')
        )

  gl.text.removeListeners = (form) ->
    $('.js-md', form).off()

) window
