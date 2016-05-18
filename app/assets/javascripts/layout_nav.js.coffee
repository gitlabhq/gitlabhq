class @LayoutNav
  $ ->
    $('#scrolling-tabs').on 'scroll', ->
      currentPosition = $(this).scrollLeft()
      return if currentPosition == 0
      maxPosition = $(this)[0].scrollWidth - $(this).parent().width()
      maxPosition += 59 if $('.nav-control').length and window.innerWidth > 480

      $('.fade-out').toggleClass('end-scroll', currentPosition is maxPosition)
