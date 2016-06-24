((w) ->

  w.gl ?= {}
  w.gl.utils ?= {}

  w.gl.utils.formatDate = (datetime) ->
    dateFormat(datetime, 'mmm d, yyyy h:MMtt Z')

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
