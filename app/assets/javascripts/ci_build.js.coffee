class @CiBuild
  constructor: ->
    @initScrollButtonAffix()

  initScrollButtonAffix: ->
    buildScroll = $('#js-build-scroll')
    body = $('body')
    buildTrace = $('#build-trace')

    buildScroll.affix(
      offset:
        bottom: ->
          body.outerHeight() - (buildTrace.outerHeight() + buildTrace.offset().top)
    )
