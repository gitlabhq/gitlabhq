# Zen Mode (full screen) textarea
#
#= provides zen_mode:enter
#= provides zen_mode:leave
#
#= require jquery.scrollTo
#= require dropzone
#= require mousetrap
#= require mousetrap/pause
#
# ### Events
#
# `zen_mode:enter`
#
# Fired when the "Edit in fullscreen" link is clicked.
#
# **Synchronicity** Sync
# **Bubbles** Yes
# **Cancelable** No
# **Target** a.js-zen-enter
#
# `zen_mode:leave`
#
# Fired when the "Leave Fullscreen" link is clicked.
#
# **Synchronicity** Sync
# **Bubbles** Yes
# **Cancelable** No
# **Target** a.js-zen-leave
#
class @ZenMode
  constructor: ->
    @active_backdrop = null
    @active_textarea = null

    $(document).on 'click', '.js-zen-enter', (e) ->
      e.preventDefault()
      $(e.currentTarget).trigger('zen_mode:enter')

    $(document).on 'click', '.js-zen-leave', (e) ->
      e.preventDefault()
      $(e.currentTarget).trigger('zen_mode:leave')

    $(document).on 'zen_mode:enter', (e) =>
      @enter(e.target.parentNode)
    $(document).on 'zen_mode:leave', (e) =>
      @exit()

    $(document).on 'keydown', (e) ->
      if e.keyCode == 27 # Esc
        e.preventDefault()
        $(document).trigger('zen_mode:leave')

  enter: (backdrop) ->
    Mousetrap.pause()

    @active_backdrop = $(backdrop)
    @active_backdrop.addClass('fullscreen')

    @active_textarea = @active_backdrop.find('textarea')

    # Prevent a user-resized textarea from persisting to fullscreen
    @active_textarea.removeAttr('style')
    @active_textarea.focus()

  exit: ->
    if @active_textarea
      Mousetrap.unpause()

      @active_textarea.closest('.zen-backdrop').removeClass('fullscreen')

      @scrollTo(@active_textarea)

      @active_textarea = null
      @active_backdrop = null

      Dropzone.forElement('.div-dropzone').enable()

  scrollTo: (zen_area) ->
    $.scrollTo(zen_area, 0, offset: -150)
