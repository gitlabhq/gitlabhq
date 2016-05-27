((w) -> 
  w.gl ?= {}
  w.gl.text ?= {}
  w.gl.text.undoManager ?= {}

  gl.text.randomString = -> Math.random().toString(36).substring(7)

  gl.text.replaceRange = (s, start, end, substitute) ->
    s.substring(0, start) + substitute + s.substring(end);

  gl.text.wrap = (textArea, tag) ->
    $textArea = $(textArea)
    oldVal = $textArea.val()
    $textArea.focus()
    textArea = $textArea.get(0)
    selObj = window.getSelection()
    selRange = selObj.getRangeAt(0)
    text = $textArea.val()
    replaceWith = @replaceRange(
        text,
        textArea.selectionStart,
        textArea.selectionEnd,
        (tag+selObj.toString()+tag))
    $textArea.data('old-val', text).val(replaceWith)
    gl.text.undoManager.addUndo(oldVal, $textArea.val())

  gl.text.prepend = (textArea, tag) ->
    $textArea = $(textArea)
    oldVal = $textArea.val()
    $textArea.focus()
    textArea = $textArea.get(0)
    selObj = window.getSelection()
    selRange = selObj.getRangeAt(0)
    text = $textArea.val()
    lineBreak = '\n' if textArea.selectionStart > 0
    console.log(textArea.selectionStart,lineBreak)
    replaceWith = @replaceRange(
      text,
      textArea.selectionStart,
      textArea.selectionEnd,
      ("#{lineBreak}#{tag} #{selObj.toString()} \n")
    )
    $textArea.data('old-val', text).val(replaceWith);
    gl.text.undoManager.addUndo(oldVal, $textArea.val())

  gl.text.undoManager.history = {}
  gl.text.undoManager.undoHistory = {}

  gl.text.undoManager.addUniqueIfNotExists = ($ta) ->
    unique = $ta.attr('data-unique')
    if not unique?
      unique = gl.text.randomString()
      $ta.attr('data-unique', unique)
      gl.text.undoManager.history[unique] = []
      gl.text.undoManager.undoHistory[unique] = []
    unique

  gl.text.undoManager.addUndo = (oldVal, newVal) ->
    $thisTextarea = $('textarea:focus')
    unique = gl.text.undoManager.addUniqueIfNotExists($thisTextarea)
    gl.text.undoManager.history[unique].push({
      oldVal: oldVal,
      newVal: newVal
    })

  gl.text.undoManager.undo = () ->
    $thisTextarea = $('textarea:focus')
    unique = gl.text.undoManager.addUniqueIfNotExists($thisTextarea)
    if not gl.text.undoManager.history[unique].length
      return
    latestChange = gl.text.undoManager.history[unique].pop()
    gl.text.undoManager.undoHistory[unique].push(latestChange)
    $thisTextarea.val(latestChange.oldVal)

  gl.text.undoManager.redo = () ->
    $thisTextarea = $('textarea:focus')
    unique = gl.text.undoManager.addUniqueIfNotExists($thisTextarea)
    if not gl.text.undoManager.undoHistory[unique].length
      return
    latestUndo = gl.text.undoManager.undoHistory[unique].pop()
    gl.text.undoManager.history[unique].push(latestUndo)
    $thisTextarea.val(latestUndo.newVal)

  gl.text.addListeners = () ->
    console.log('addListeners')
    self = @
    $('.js-md').on 'click', ->
      $this = $(@)
      if $this.data('md-wrap')?
        self.wrap(
          $this.closest('.md-area').find('textarea'),
          $this.data('md-tag')
        )  
      else if $this.data('md-prepend')?
        self.prepend(
          $this.closest('.md-area').find('textarea'),
          $this.data('md-tag')
        )
      else
        self.wrap(
          $this.closest('.md-area').find('textarea'),
          $this.data('md-tag')
        )

    $(window).on 'keydown', (e) =>
      if e.ctrlKey or e.metaKey
        if String.fromCharCode(e.which).toLowerCase() is 'z' and !e.shiftKey
          e.preventDefault()
          self.undoManager.undo()
        else if ((String.fromCharCode(e.which).toLowerCase() is 'z' and e.shiftKey) or (String.fromCharCode(e.which).toLowerCase() is 'y'))
          e.preventDefault()
          self.undoManager.redo()

  gl.text.removeListeners = () ->
    $('js-md.btn-bold').off()

) window