class @GLFormActions
  constructor: (@form, @textarea) ->
    @clearEventListeners()
    @addEventListeners()

  clearEventListeners: ->
    @form.off 'click', '.js-toolbar-button'

  addEventListeners: ->
    @form.on 'click', '.js-toolbar-button', @toolbarButtonClick

  toolbarButtonClick: (e) =>
    $btn = $(e.currentTarget)

    # Get the prefix from the button
    prefix = $btn.data('prefix')
    @addPrefixToTextarea(prefix)

  addPrefixToTextarea: (prefix) ->
    caretStart = @textarea.get(0).selectionStart
    caretEnd = @textarea.get(0).selectionEnd
    textEnd = @textarea.val().length

    beforeSelection = @textarea.val().substring 0, caretStart
    afterSelection = @textarea.val().substring caretEnd, textEnd

    beforeSelectionSplit = beforeSelection.split ''
    beforeSelectionLength = beforeSelection.length

    # Get the last character in the before selection
    beforeSelectionLastChar = beforeSelectionSplit[beforeSelectionLength - 1]

    if beforeSelectionLastChar? and beforeSelectionLastChar isnt ''
      # Append a white space char to the prefix if the previous char isn't a space
      prefix = " #{prefix}"

    # Update the textarea
    @textarea.val beforeSelection + prefix + afterSelection
    @textarea.get(0).setSelectionRange caretStart + prefix.length, caretEnd + prefix.length

    # Focus the textarea
    @textarea.focus()
    @textarea.trigger('keyup')
