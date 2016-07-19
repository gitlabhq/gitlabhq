((w) ->

  w.gl ?= {}
  w.gl.utils ?= {}
  w.gl.utils.days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']

  w.gl.utils.formatDate = (datetime) ->
    dateFormat(datetime, 'mmm d, yyyy h:MMtt Z')

  w.gl.utils.getDayName = (date) ->
    this.days[date.getDay()]

  w.gl.utils.localTimeAgo = ($timeagoEls, setTimeago = true) ->
    $timeagoEls.each( ->
          $el = $(@)
          $el.attr('title', gl.utils.formatDate($el.attr('datetime')))
    )

    if setTimeago
      $timeagoEls.timeago()
      $timeagoEls.tooltip('destroy')

      # Recreate with custom template
      $timeagoEls.tooltip(
        template: '<div class="tooltip local-timeago" role="tooltip"><div class="tooltip-arrow"></div><div class="tooltip-inner"></div></div>'
      )

) window
