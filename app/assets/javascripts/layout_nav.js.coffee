class @LayoutNav
  $ ->
    $('#scrolling-tabs').on 'scroll', ->
      currentPosition = $(this).scrollLeft()
      return if currentPosition is 0
      mobileScreenWidth = 480
      controlBtnWidth = $('.controls').width()
      maxPosition = $(this)[0].scrollWidth - $(this).parent().width()
      maxPosition += controlBtnWidth if $('.nav-control').length and $(window).width() > mobileScreenWidth

      $('.fade-out').toggleClass('end-scroll', currentPosition is maxPosition)
