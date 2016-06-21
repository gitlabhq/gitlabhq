#= require shortcuts

class @ShortcutsBlob extends Shortcuts
  constructor: (skipResetBindings) ->
    super skipResetBindings
    Mousetrap.bind('y', ShortcutsBlob.copyToClipboard)

  @copyToClipboard: ->
    clipboardButton = $('.btn-clipboard')
    clipboardButton.click() if clipboardButton
