class @LayoutNav
  $ ->
    $('.fade-left').addClass('end-scroll')
    $('.scrolling-tabs').on 'scroll', (event) ->
      $this = $(this)
      $el = $(event.target)
      currentPosition = $this.scrollLeft()
      size = bp.getBreakpointSize()
      controlBtnWidth = $('.controls').width()
      maxPosition = $this.get(0).scrollWidth - $this.parent().width()
      maxPosition += controlBtnWidth if size isnt 'xs' and $('.nav-control').length

      $el.find('.fade-left').toggleClass('end-scroll', currentPosition is 0)
      $el.find('.fade-right').toggleClass('end-scroll', currentPosition is maxPosition)
