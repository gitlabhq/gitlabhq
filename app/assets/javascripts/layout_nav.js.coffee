class @LayoutNav
  $ ->
    $('#scrolling-tabs').on 'scroll', ->
      currentPosition = $(this).scrollLeft()
      return if currentPosition == 0
      if $('.nav-control').length
        maxPosition = $(this)[0].scrollWidth - $(this).parent().width() + 59
      else
        maxPosition = $(this)[0].scrollWidth - $(this).parent().width()

      $('.fade-out').toggleClass('end-scroll', currentPosition is maxPosition)
