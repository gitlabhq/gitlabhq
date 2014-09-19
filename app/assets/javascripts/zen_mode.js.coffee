class @ZenMode
  @fullscreen_prefix = 'fullscreen_'

  constructor: ->
    @active_zen_area = null
    @active_checkbox = null

    $('body').on 'change', '.zennable input[type=checkbox]', (e) =>
      checkbox = e.currentTarget
      if checkbox.checked
        Mousetrap.pause()
        @udpateActiveZenArea(checkbox)
      else
        @exitZenMode()

    $(document).on 'keydown', (e) =>
      if e.keyCode is $.ui.keyCode.ESCAPE
        @exitZenMode()

    $(window).on 'hashchange', @updateZenModeFromLocationHash

  udpateActiveZenArea: (checkbox) =>
    @active_checkbox = $(checkbox)
    @active_checkbox.prop('checked', true)
    @active_zen_area = @active_checkbox.parent().find('textarea')
    @active_zen_area.focus()
    window.location.hash = ZenMode.fullscreen_prefix + @active_checkbox.prop('id')

  exitZenMode: =>
    if @active_zen_area isnt null
      Mousetrap.unpause()
      @active_checkbox.prop('checked', false)
      @active_zen_area = null
      @active_checkbox = null
      window.location.hash = ''

  checkboxFromLocationHash: (e) ->
    id = $.trim(window.location.hash.replace('#' + ZenMode.fullscreen_prefix, ''))
    if id
      return $('.zennable input[type=checkbox]#' + id)[0]
    else
      return null

  updateZenModeFromLocationHash: (e) =>
    checkbox = @checkboxFromLocationHash()
    if checkbox
      @udpateActiveZenArea(checkbox)
    else
      @exitZenMode()
