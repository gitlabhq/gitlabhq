class @LayoutNav
  $ ->
    $('.fade-left').addClass('end-scroll')
    $('.scrolling-tabs').scroll (event) ->
      el = $(event.target)
      currentPosition = $(this).scrollLeft()
      mobileScreenWidth = 480
      controlBtnWidth = $('.controls').width()
      maxPosition = $(this)[0].scrollWidth - $(this).parent().width()
      maxPosition += controlBtnWidth if $('.nav-control').length and $(window).width() > mobileScreenWidth

      el.find('.fade-left').toggleClass('end-scroll', currentPosition is 0)
      el.find('.fade-right').toggleClass('end-scroll', currentPosition is maxPosition)
