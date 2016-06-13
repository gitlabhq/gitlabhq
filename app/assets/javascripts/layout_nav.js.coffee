hideEndFade = ($scrollingTabs) ->
  $scrollingTabs.each ->
    $this = $(@)

    $this
      .find('.fade-right')
      .toggleClass('end-scroll', $this.width() is $this.prop('scrollWidth'))

$ ->
  $('.fade-left').addClass('end-scroll')

  hideEndFade($('.scrolling-tabs'))

  $(window)
    .off 'resize.nav'
    .on 'resize.nav', ->
      hideEndFade($('.scrolling-tabs'))

  $('.scrolling-tabs').on 'scroll', (event) ->
    $this = $(this)
    $el = $(event.target)
    currentPosition = $this.scrollLeft()
    size = bp.getBreakpointSize()
    controlBtnWidth = $('.controls').width()
    maxPosition = ($this.get(0).scrollWidth - $this.parent().width()) - 1
    # maxPosition += controlBtnWidth if size isnt 'xs' and $('.nav-control').length
    console.log maxPosition, currentPosition

    $el.find('.fade-left').toggleClass('end-scroll', currentPosition is 0)
    $el.find('.fade-right').toggleClass('end-scroll', currentPosition is maxPosition)
