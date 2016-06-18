((w) -> 
  if not w.gl? then w.gl = {}
  if not gl.animate? then gl.animate = {}

  gl.animate.animate = ($el, animation, options, done) ->
    if options?.cssStart?
      $el.css(options.cssStart)
    $el
      .removeClass(animation + ' animated')
      .addClass(animation + ' animated')
      .one 'webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend', ->
        $(this).removeClass(animation + ' animated')
        if done?
          done()
        if options?.cssEnd?
          $el.css(options.cssEnd)
        return
    return

  gl.animate.animateEach = ($els, animation, time, options, done) ->
    dfd = $.Deferred()
    if not $els.length
      dfd.resolve()
    $els.each((i) ->
      setTimeout(=>
        $this = $(@)
        gl.animate.animate($this, animation, options, =>
          if i is $els.length - 1
            dfd.resolve()
            if done?
              done()
        )
      ,time * i
      )
      return
    )
    return dfd.promise()
  return 
) window