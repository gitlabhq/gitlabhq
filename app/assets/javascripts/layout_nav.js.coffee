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
    currentPosition = $this.scrollLeft()
    maxPosition = $this.prop('scrollWidth') - $this.outerWidth()

    $this.find('.fade-left').toggleClass('end-scroll', currentPosition is 0)
    $this.find('.fade-right').toggleClass('end-scroll', currentPosition is maxPosition)
