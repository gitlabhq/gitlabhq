#= require shortcuts_navigation

class @ShortcutsFindFile extends ShortcutsNavigation
  constructor: (@projectFindFile) ->
    super()
    _oldStopCallback = Mousetrap.stopCallback
    # override to fire shortcuts action when focus in textbox
    Mousetrap.stopCallback = (event, element, combo) =>
      if element == @projectFindFile.inputElement[0] and (combo == 'up' or combo == 'down' or combo == 'esc' or combo == 'enter')
        # when press up/down key in textbox, cusor prevent to move to home/end
        event.preventDefault()
        return false

      return _oldStopCallback(event, element, combo)

    Mousetrap.bind('up', @projectFindFile.selectRowUp)
    Mousetrap.bind('down', @projectFindFile.selectRowDown)
    Mousetrap.bind('esc', @projectFindFile.goToTree)
    Mousetrap.bind('enter', @projectFindFile.goToBlob)
