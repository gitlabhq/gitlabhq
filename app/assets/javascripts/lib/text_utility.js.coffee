((w) -> 
  w.gl ?= {}
  w.gl.text ?= {}
  w.gl.text.undoManager ?= {}

  gl.text.replaceRange = (s, start, end, substitute) ->
    s.substring(0, start) + substitute + s.substring(end);

  gl.text.wrap = (textArea, tag) ->
    $textArea = $(textArea)
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
    $textArea.data('old-val', text).val(replaceWith);

  gl.text.prepend = (textArea, tag) ->
    $textArea = $(textArea)
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
    # $textArea.val(replaceWith)

  gl.text.undoManager.undo = () ->
    

  gl.text.addListeners = () ->
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

    $(window).on 'keydown', (e) ->
      if e.ctrlKey or e.metaKey
        if String.fromCharCode(e.which).toLowerCase() is 'z' and !e.shiftKey
          e.preventDefault()
        else if ((String.fromCharCode(e.which).toLowerCase() is 'z' and e.shiftKey) or (String.fromCharCode(e.which).toLowerCase() is 'y'))
          e.preventDefault()

  gl.text.removeListeners = () ->
    $('js-md.btn-bold').off()

) window