hideEndFade = ($scrollingTabs) ->
  $scrollingTabs.each ->
    $this = $(@)

    $this
      .siblings('.fade-right')
      .toggleClass('scrolling', $this.width() < $this.prop('scrollWidth'))

$ ->

  hideEndFade($('.scrolling-tabs'))

  $(window)
    .off 'resize.nav'
    .on 'resize.nav', ->
      hideEndFade($('.scrolling-tabs'))

  $('.scrolling-tabs').on 'scroll', (event) ->
    $this = $(this)
    currentPosition = $this.scrollLeft()
    maxPosition = $this.prop('scrollWidth') - $this.outerWidth()

    $this.siblings('.fade-left').toggleClass('scrolling', currentPosition > 0)
    $this.siblings('.fade-right').toggleClass('scrolling', currentPosition < maxPosition - 1)
