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

    $timeagoEls.timeago() if setTimeago

) window
