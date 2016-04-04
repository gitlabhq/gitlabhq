((w) -> 

  w.glAnimate = ($el, animation, done) ->
    $el
      .removeClass()
      .addClass(animation + ' animated')
      .one 'webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend', ->
        $(this).removeClass()
        return
    return
  return

) window