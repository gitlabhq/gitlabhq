class @LayoutNav
  $ ->
    $('.fade-left').addClass('end-scroll')
    $('#scrolling-tabs').on 'scroll', ->
      currentPosition = $(this).scrollLeft()
      $('.fade-left').toggleClass('end-scroll', currentPosition is 0)

      mobileScreenWidth = 480
      controlBtnWidth = $('.controls').width()
      maxPosition = $(this)[0].scrollWidth - $(this).parent().width()
      maxPosition += controlBtnWidth if $('.nav-control').length and $(window).width() > mobileScreenWidth

      $('.fade-right').toggleClass('end-scroll', currentPosition is maxPosition)
