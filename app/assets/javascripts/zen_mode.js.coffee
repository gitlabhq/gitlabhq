#= require dropzone
#= require mousetrap
#= require mousetrap/pause

class @ZenMode
  constructor: ->
    @active_zen_area = null
    @active_checkbox = null
    @scroll_position = 0

    $(window).scroll =>
      if not @active_checkbox
        @scroll_position = window.pageYOffset

    $('body').on 'click', '.zen-enter-link', (e) =>
      e.preventDefault()
      $(e.currentTarget).closest('.zennable').find('.zen-toggle-comment').prop('checked', true).change()

    $('body').on 'click', '.zen-leave-link', (e) =>
      e.preventDefault()
      $(e.currentTarget).closest('.zennable').find('.zen-toggle-comment').prop('checked', false).change()

    $('body').on 'change', '.zen-toggle-comment', (e) =>
      checkbox = e.currentTarget
      if checkbox.checked
        # Disable other keyboard shortcuts in ZEN mode
        Mousetrap.pause()
        @updateActiveZenArea(checkbox)
      else
        @exitZenMode()

    $(document).on 'keydown', (e) =>
      if e.keyCode is 27 # Esc
        @exitZenMode()
        e.preventDefault()

  updateActiveZenArea: (checkbox) =>
    @active_checkbox = $(checkbox)
    @active_checkbox.prop('checked', true)
    @active_zen_area = @active_checkbox.parent().find('textarea')
    # Prevent a user-resized textarea from persisting to fullscreen
    @active_zen_area.removeAttr('style')
    @active_zen_area.focus()

  exitZenMode: =>
    if @active_zen_area isnt null
      Mousetrap.unpause()
      @active_checkbox.prop('checked', false)
      @active_zen_area = null
      @active_checkbox = null
      @restoreScroll(@scroll_position)
      # Enable dropzone when leaving ZEN mode
      Dropzone.forElement('.div-dropzone').enable()

  restoreScroll: (y) ->
    window.scrollTo(window.pageXOffset, y)
