class @LayoutNav
  $(document).ready ->
    $('#scrolling-tabs').on 'scroll', ->
      cur = $(this).scrollLeft()
      if cur == 0
        return
      else
        max = 289
        console.log "MAX:" + max
        console.log "CUR:" + cur
        if cur == max
          $('.fa-arrow-right').addClass('end-scroll')
          $('.nav-links').addClass('end-scroll')
        else
          $('.fa-arrow-right').removeClass('end-scroll')
          $('.nav-links').removeClass('end-scroll')
      return
    $('#scrolling-tabs').trigger 'scroll'
    return
